{ lib }:
let
  # -- helpers ---------------------------------------------------------

  mkOpt =
    type: default:
    lib.mkOption {
      type = lib.types.nullOr type;
      inherit default;
    };

  helpers = {
    mkStr = mkOpt lib.types.str;
    mkBool = mkOpt lib.types.bool;
    mkInt = mkOpt lib.types.int;
    mkPort = mkOpt lib.types.port;
    mkPath = mkOpt lib.types.path;
    mkLines = mkOpt lib.types.lines;
    mkPackage = mkOpt lib.types.package;
    mkRaw = mkOpt lib.types.raw;
    mkEnum = values: mkOpt (lib.types.enum values);
    mkList = elem: mkOpt (lib.types.listOf elem);
    mkAttrsOf = val: mkOpt (lib.types.attrsOf val);
    mkEither = a: b: mkOpt (lib.types.either a b);
    mkSub =
      opts:
      lib.mkOption {
        type = lib.types.submodule { options = opts; };
        default = { };
      };
    mkSubList =
      opts:
      lib.mkOption {
        type = lib.types.listOf (lib.types.submodule { options = opts; });
        default = [ ];
      };
  };

  # -- scanning --------------------------------------------------------

  defaultExclude =
    { name, ... }:
    let
      c = builtins.substring 0 1 name;
    in
    c == "_" || c == "." || name == "flake.nix" || name == "default.nix";

  scanDir =
    exclude: dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if exclude { inherit name path; } then
          [ ]
        else if type == "directory" then
          scanDir exclude path
        else if type == "regular" && lib.hasSuffix ".nix" name then
          [ path ]
        else if type == "symlink" then
          builtins.trace "[nixy/scan] skipping symlink: ${toString path}" [ ]
        else
          [ ]
      ) (builtins.readDir dir)
    );

  resolveImport =
    exclude: x:
    if builtins.isPath x then
      if lib.hasSuffix ".nix" (toString x) then
        [ x ]
      else if builtins.pathExists x then
        scanDir exclude x
      else
        [ ]
    else if builtins.isString x then
      if builtins.substring 0 1 x == "/" then
        resolveImport exclude (/. + x)
      else
        throw "[nixy/scan] relative string path '${x}' not supported; use a path literal"
    else if builtins.isAttrs x then
      [ x ]
    else if builtins.isList x then
      lib.concatMap (resolveImport exclude) x
    else
      throw "[nixy/scan] invalid import: ${builtins.typeOf x}";

  loadFile =
    x:
    if builtins.isPath x then
      lib.setDefaultModuleLocation (toString x) (import x)
    else if builtins.isAttrs x then
      { _file = "<inline>"; } // x
    else
      x;

  # -- schema ----------------------------------------------------------

  isOption = x: builtins.isAttrs x && (x._type or null) == "option";

  buildSchemaOpts =
    prefix: attrs:
    lib.mapAttrs (
      name: value:
      let
        path = if prefix == "" then name else "${prefix}.${name}";
      in
      if isOption value then
        value
      else if builtins.isAttrs value then
        lib.mkOption {
          type = lib.types.submodule { options = buildSchemaOpts path value; };
          default = { };
        }
      else
        throw "[nixy/schema] '${path}': expected option or attrset"
    ) attrs;

  # -- types -----------------------------------------------------------

  deepMerge = lib.mkOptionType {
    name = "deepMerge";
    check = builtins.isAttrs;
    merge = _: defs: lib.foldl' lib.recursiveUpdate { } (map (d: d.value) defs);
  };

  traitType = lib.types.submodule {
    options = {
      name = lib.mkOption { type = lib.types.str; };
      module = lib.mkOption {
        type = lib.types.either (lib.types.functionTo lib.types.raw) lib.types.attrs;
      };
    };
  };

  # -- trait index -----------------------------------------------------

  buildTraitIndex =
    traits:
    let
      grouped = lib.groupBy (t: t.name) traits;
      dups = lib.filterAttrs (_: v: builtins.length v > 1) grouped;
    in
    lib.throwIf (dups != { })
      "[nixy/traits] duplicate names: ${lib.concatStringsSep ", " (builtins.attrNames dups)}"
      (lib.listToAttrs (map (t: lib.nameValuePair t.name t) traits));

  # -- module form detection -------------------------------------------

  # True when fn's formal parameters contain a canonical NixOS module
  # argument, meaning it is a plain NixOS module — not a nixy outer.
  nixosArgs = [
    "config"
    "options"
    "pkgs"
    "lib"
    "modulesPath"
  ];

  isNixosModuleFn =
    fn:
    let
      fargs = builtins.functionArgs fn;
    in
    builtins.any (a: fargs ? ${a}) nixosArgs;

  # -- module resolution -----------------------------------------------

  # Normalise any module value into a NixOS-ready module.
  #
  # Three input forms:
  #   1. { framework }: { nixos }: { ... }   — call outer with frameworkArgs
  #   2. { nixos }: { ... }                  — pass through
  #   3. { ... }  (attrset)                  — pass through
  #
  # Paths are imported first, then the same logic applies.
  resolveModule =
    fwArgs: tag: m:
    if builtins.isPath m then
      let
        loc = toString m;
        imported = import m;
      in
      if builtins.isFunction imported then
        lib.setDefaultModuleLocation loc (if isNixosModuleFn imported then imported else imported fwArgs)
      else
        lib.setDefaultModuleLocation loc imported
    else if builtins.isFunction m then
      lib.setDefaultModuleLocation tag (if isNixosModuleFn m then m else m fwArgs)
    else if builtins.isAttrs m then
      { _file = tag; } // m
    else
      throw "[nixy] ${tag}: unsupported type '${builtins.typeOf m}'";

  # -- node building ---------------------------------------------------

  buildNode =
    {
      name,
      node,
      traitIndex,
      allNodes,
      userArgs,
    }:
    let
      missing = builtins.filter (t: !(traitIndex ? ${t})) node.traits;

      # Force-evaluate schema values early so type errors surface here
      # (with nixy's addErrorContext) instead of deep inside NixOS eval.
      conf = lib.deepSeq node.schema node.schema;

      # Core framework values on the right — they must not be shadowed
      # by anything the user passes in args.
      frameworkArgs = userArgs // {
        inherit name conf;
        nodes = lib.mapAttrs (_: n: { inherit (n) meta schema traits; }) allNodes;
      };

      resolve = resolveModule frameworkArgs;

      traitModules = map (
        tName:
        builtins.addErrorContext "while evaluating trait '${tName}' for node '${name}'" (
          resolve "nixy: trait '${tName}', node '${name}'" traitIndex.${tName}.module
        )
      ) node.traits;

      includeModules = lib.imap0 (
        idx: m:
        builtins.addErrorContext "while evaluating include[${toString idx}] for node '${name}'" (
          resolve "nixy: include[${toString idx}], node '${name}'" m
        )
      ) node.includes;
    in
    lib.throwIf (missing != [ ])
      "[nixy/node '${name}'] unknown traits: ${lib.concatStringsSep ", " missing}"
      {
        module = {
          imports = traitModules ++ includeModules;
        };
        meta = node.meta;
      };

  # -- core module -----------------------------------------------------

  mkCore =
    { userArgs }:
    { config, ... }:
    let
      traitIndex = buildTraitIndex config.traits;
      schemaOpts = buildSchemaOpts "" config.schema;

      nodeType = lib.types.submodule {
        options = {
          meta = lib.mkOption {
            type = deepMerge;
            default = { };
          };
          traits = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          schema = lib.mkOption {
            type = lib.types.submodule { options = schemaOpts; };
            default = { };
          };
          includes = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
          };
        };
      };

      builtNodes = lib.mapAttrs (
        nodeName: node:
        builtins.addErrorContext "while building node '${nodeName}'" (buildNode {
          name = nodeName;
          inherit node traitIndex userArgs;
          allNodes = config.nodes;
        })
      ) config.nodes;
    in
    {
      _file = "<nixy/core>";

      options = {
        schema = lib.mkOption {
          type = deepMerge;
          default = { };
        };
        traits = lib.mkOption {
          type = lib.types.listOf traitType;
          default = [ ];
        };
        nodes = lib.mkOption {
          type = lib.types.attrsOf nodeType;
          default = { };
        };
        _result = lib.mkOption {
          type = lib.types.raw;
          internal = true;
        };
      };

      config._result = {
        nodes = builtNodes;
        _nixy = {
          traitNames = map (t: t.name) config.traits;
          nodeNames = builtins.attrNames config.nodes;
        };
      };
    };

in
{
  meta.version = "0.8.0";
  inherit helpers;

  eval =
    {
      imports ? [ ],
      args ? { },
      exclude ? null,
    }:
    let
      excludeFn = if exclude != null then exclude else defaultExclude;
      resolved = lib.concatMap (resolveImport excludeFn) (lib.toList imports);
      core = mkCore { userArgs = args; };
      evaluated = lib.evalModules {
        class = "nixy";
        modules = map loadFile resolved ++ [ core ];
        specialArgs = {
          inherit lib;
        }
        // helpers
        // args;
      };
    in
    evaluated.config._result;
}

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

  validName = s: builtins.match "[a-zA-Z_][a-zA-Z0-9_-]*" s != null;

  flattenSchema =
    prefix: attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          path = if prefix == "" then name else "${prefix}.${name}";
        in
        if isOption value then
          let
            segs = lib.splitString "." path;
            bad = lib.findFirst (s: !(validName s)) null segs;
          in
          lib.throwIf (bad != null) "[nixy/schema] '${path}': invalid segment '${bad}'"
            [{ inherit path; option = value; }]
        else if builtins.isAttrs value then
          flattenSchema path value
        else
          throw "[nixy/schema] '${path}': expected option or attrset"
      ) attrs
    );

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
      name = lib.mkOption {
        type = lib.types.str;
        description = "Unique identifier for this trait.";
      };
      module = lib.mkOption {
        type = lib.types.raw;
        description = "NixOS/Darwin/HM module (function or attrset).";
      };
    };
  };

  ruleType = lib.types.submodule {
    options = {
      assertion = lib.mkOption { type = lib.types.bool; };
      message = lib.mkOption { type = lib.types.str; };
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

      frameworkArgs =
        {
          inherit name;
          conf = node.schema;
          nodes = lib.mapAttrs (_: n: { inherit (n) meta schema traits; }) allNodes;
        }
        // userArgs;

      # Resolve a trait's module into a NixOS-ready module.
      #
      # Traits use the two-function form:
      #   module = { conf, nodes, ... }: { config, pkgs, ... }: { ... };
      #
      # The outer function takes framework args and returns a NixOS module.
      resolveTraitModule =
        tName:
        let
          m = traitIndex.${tName}.module;
          loc = "nixy: trait '${tName}', node '${name}'";
        in
        builtins.addErrorContext "while evaluating trait '${tName}' for node '${name}'" (
          if !builtins.isFunction m then
            # Attrset module — pass through with location tag
            lib.setDefaultModuleLocation loc m
          else
            # Two-function form → call outer with framework args.
            # The result is a standard NixOS module.
            lib.setDefaultModuleLocation loc (m frameworkArgs)
        );

      # Resolve an include module to support framework args.
      #
      # Includes can be:
      #   1) Attrset modules: pass through unchanged
      #   2) Functions with framework args:
      #        { conf, name, nodes, ... }: { config, pkgs, ... }: { ... }
      #   3) Direct NixOS modules (for backward compatibility):
      #        { config, pkgs, ... }: { ... }
      #
      # We wrap function-based includes to provide framework args.
      resolveIncludeModule =
        idx: m:
        let
          loc = "nixy: include[${toString idx}], node '${name}'";
        in
        builtins.addErrorContext "while evaluating include[${toString idx}] for node '${name}'" (
          if !builtins.isFunction m then
            # Attrset module — pass through with location tag
            lib.setDefaultModuleLocation loc m
          else
            # Function module — call with framework args and let it return a NixOS module
            lib.setDefaultModuleLocation loc (m frameworkArgs)
        );

      traitModules = map resolveTraitModule node.traits;
      includeModules = lib.imap0 resolveIncludeModule node.includes;
    in
    lib.throwIf (missing != [ ])
      "[nixy/node '${name}'] unknown traits: ${lib.concatStringsSep ", " missing}"
      {
        module = { imports = traitModules ++ includeModules; };
        meta = node.meta;
      };

  # -- core module -----------------------------------------------------

  mkCore =
    { userArgs }:
    { config, ... }:
    let
      schemaEntries = flattenSchema "" config.schema;
      traitIndex = buildTraitIndex config.traits;
      traitNames = map (t: t.name) config.traits;
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
            type = lib.types.listOf lib.types.deferredModule;
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

      rulesErrs = map (r: r.message) (builtins.filter (r: !r.assertion) config.rules);

      checked =
        lib.throwIf (rulesErrs != [ ])
          ("[nixy/rules]\n" + lib.concatMapStringsSep "\n" (e: "  - ${e}") rulesErrs)
          builtNodes;
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
        rules = lib.mkOption {
          type = lib.types.listOf ruleType;
          default = [ ];
        };
        _result = lib.mkOption {
          type = lib.types.raw;
          internal = true;
        };
      };

      config._result = {
        nodes = checked;
        _nixy = {
          inherit schemaEntries traitNames;
          nodeNames = builtins.attrNames config.nodes;
          nodes = lib.mapAttrs (_: n: { inherit (n) meta traits schema; }) config.nodes;
        };
      };
    };

in
{
  meta.version = "0.7.0";
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
        specialArgs = { inherit lib; } // helpers // args;
      };
    in
    evaluated.config._result;
}

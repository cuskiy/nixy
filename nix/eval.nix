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

  # -- schema introspection --------------------------------------------
  describeType = opt:
    let
      d = opt.type.description or opt.type.name or "?";
    in
    if builtins.isString d then d else toString d;

  describeDefault = opt:
    let
      r = builtins.tryEval (
        if !(opt ? default) then "—"
        else if opt.default == null then "null"
        else lib.generators.toPretty { } opt.default
      );
    in
    if r.success then r.value else "…";

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

  # -- module form detection -------------------------------------------
  # A function is a "plain NixOS module" if its formal parameters include
  # any of the canonical NixOS-specific argument names.  Otherwise it is
  # treated as the outer layer of the two-function form and will be called
  # with frameworkArgs.
  isNixosModuleFn =
    fn:
    let
      fargs = builtins.functionArgs fn;
    in
    fargs ? config || fargs ? pkgs || fargs ? options || fargs ? modulesPath;

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

      # Traits always use the two-function form:
      #   module = { conf, nodes, ... }: { config, pkgs, ... }: { ... };
      # The outer function takes framework args, returns a NixOS module.
      resolveTraitModule =
        tName:
        let
          m = traitIndex.${tName}.module;
          loc = "nixy: trait '${tName}', node '${name}'";
        in
        builtins.addErrorContext "while evaluating trait '${tName}' for node '${name}'" (
          if !builtins.isFunction m then
            lib.setDefaultModuleLocation loc m
          else
            lib.setDefaultModuleLocation loc (m frameworkArgs)
        );

      # Includes support two forms:
      #
      #   1) Plain NixOS module (path, attrset, or function with NixOS args):
      #        ../hardware-configuration.nix
      #        { services.foo.enable = true; }
      #        { config, pkgs, ... }: { ... }
      #      → passed through to NixOS unchanged.
      #
      #   2) Two-function form (outer has framework args):
      #        { conf, ... }: { config, pkgs, ... }: { ... }
      #      → outer called with frameworkArgs, result passed to NixOS.
      #
      # Detection: if the function's formal parameters include any NixOS-
      # specific names (config, pkgs, options, modulesPath), it's a plain
      # NixOS module.  Otherwise it's a two-function form.
      resolveIncludeModule =
        idx: m:
        builtins.addErrorContext
          "while evaluating include[${toString idx}] for node '${name}'" (
          if builtins.isPath m then
            let
              loc = toString m;
              imported = import m;
            in
            if !builtins.isFunction imported then
              lib.setDefaultModuleLocation loc imported
            else if isNixosModuleFn imported then
              lib.setDefaultModuleLocation loc imported
            else
              lib.setDefaultModuleLocation loc (imported frameworkArgs)

          else if builtins.isFunction m then
            let
              loc = "nixy: include[${toString idx}], node '${name}'";
            in
            if isNixosModuleFn m then
              lib.setDefaultModuleLocation loc m
            else
              lib.setDefaultModuleLocation loc (m frameworkArgs)

          else if builtins.isAttrs m then
            { _file = "nixy: include[${toString idx}], node '${name}'"; } // m

          else
            throw "[nixy/node '${name}'] include[${toString idx}]: unsupported type '${builtins.typeOf m}'"
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
          # listOf raw — we need the original values (paths, functions,
          # attrsets) so buildNode can import, detect forms, and inject
          # framework args.  deferredModule would wrap them opaquely.
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

      rulesErrs = map (r: r.message) (builtins.filter (r: !r.assertion) config.rules);

      checked =
        lib.throwIf (rulesErrs != [ ])
          ("[nixy/rules]\n" + lib.concatMapStringsSep "\n" (e: "  - ${e}") rulesErrs)
          builtNodes;

      # -- introspection / formatting ------------------------------------
      nodeNames = builtins.attrNames config.nodes;
      len = builtins.length;

      fmtCheck =
        let
          fmtField =
            e:
            "| `${e.path}` | ${describeType e.option} | `${describeDefault e.option}` |";
        in
        lib.concatStringsSep "\n" (
          [
            "# Schema"
            "> ${toString (len schemaEntries)} fields"
          ]
          ++ lib.optionals (schemaEntries != [ ]) [
            "| Field | Type | Default |"
            "|-------|------|---------|"
            (lib.concatMapStringsSep "\n" fmtField schemaEntries)
          ]
          ++ [
            ""
            "# Traits"
            "> ${toString (len traitNames)}${
              lib.optionalString (traitNames != [ ]) ": ${lib.concatStringsSep ", " traitNames}"
            }"
            ""
            "# Nodes"
            "> ${toString (len nodeNames)}${
              lib.optionalString (nodeNames != [ ]) ": ${lib.concatStringsSep ", " nodeNames}"
            }"
          ]
        );

      fmtShow = lib.mapAttrs (
        nodeName: node:
        let
          getVal =
            path:
            let
              r = builtins.tryEval (lib.attrByPath (lib.splitString "." path) null node.schema);
            in
            if r.success then r.value else null;
          fmtVal =
            v:
            if v == null then
              "null"
            else
              let
                r = builtins.tryEval (builtins.toJSON v);
              in
              if r.success then r.value else "…";
          fmtInclude =
            i:
            if builtins.isPath i then
              toString i
            else if builtins.isAttrs i then
              "{ … }"
            else
              "<function>";
        in
        lib.concatStringsSep "\n" (
          [
            "# Node: ${nodeName}"
            ""
            "system: ${node.meta.system or "unknown"}"
            "traits: [${lib.concatMapStringsSep " " (t: " \"${t}\"") node.traits} ]"
          ]
          ++ [
            ""
            "## Schema"
          ]
          ++ map (e: "  ${e.path} = ${fmtVal (getVal e.path)}") schemaEntries
          ++ [ "" "## Includes" ]
          ++ (
            if node.includes == [ ] then
              [ "  (none)" ]
            else
              lib.imap0 (
                i: inc: "  [${toString i}] ${fmtInclude inc}"
              ) node.includes
          )
        )
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
          inherit schemaEntries traitNames nodeNames;
          nodes = lib.mapAttrs (_: n: { inherit (n) meta traits schema; }) config.nodes;
          fmt = {
            check = fmtCheck;
            show = fmtShow;
          };
        };
      };
    };

in
{
  meta.version = "0.7.3";
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

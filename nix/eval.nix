{
  lib,
  imports ? [ ],
  args ? { },
  exclude ? null,
}:

let
  # -- helpers ---------------------------------------------------------------

  mkOpt =
    type: default:
    lib.mkOption {
      type = lib.types.nullOr type;
      inherit default;
    };

  mkReq =
    type:
    lib.mkOption { inherit type; };

  helpers = {
    inherit mkOpt mkReq;
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
    mkOneOf = ts: mkOpt (lib.types.oneOf ts);
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

  # -- file scanning ---------------------------------------------------------

  defaultExclude =
    { name, ... }:
    let
      c = builtins.substring 0 1 name;
    in
    c == "_" || c == "." || name == "flake.nix" || name == "default.nix";

  scanDir =
    excl: dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if excl { inherit name path; } then
          [ ]
        else if type == "directory" then
          scanDir excl path
        else if type == "regular" && lib.hasSuffix ".nix" name then
          [ path ]
        else
          [ ]
      ) (builtins.readDir dir)
    );

  resolveImport =
    excl: x:
    if builtins.isFunction x || builtins.isAttrs x then
      [ x ]
    else if builtins.isPath x then
      if lib.hasSuffix ".nix" (toString x) then
        [ x ]
      else if builtins.pathExists x then
        scanDir excl x
      else
        [ ]
    else if builtins.isList x then
      lib.concatMap (resolveImport excl) x
    else
      throw "[nixy] unsupported import type: ${builtins.typeOf x}";

  # -- module loading --------------------------------------------------------

  tag =
    label: m:
    if builtins.isFunction m || builtins.isAttrs m then
      lib.setDefaultModuleLocation label m
    else
      throw "[nixy] ${label}: expected function or attrset, got ${builtins.typeOf m}";

  loadModule = label: m: if builtins.isPath m then tag (toString m) (import m) else tag label m;

  loadFile =
    x: if builtins.isPath x then loadModule (toString x) (import x) else loadModule "<inline>" x;

  # -- schema → options ------------------------------------------------------

  isOption = x: builtins.isAttrs x && (x._type or null) == "option";

  toOptions =
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
          type = lib.types.submodule { options = toOptions path value; };
          default = { };
        }
      else
        throw "[nixy] schema '${path}': expected option or attrset, got ${builtins.typeOf value}"
    ) attrs;

  # -- types -----------------------------------------------------------------

  deepMerge = lib.types.mkOptionType {
    name = "deepMerge";
    check = builtins.isAttrs;
    merge = _: defs: lib.foldl' lib.recursiveUpdate { } (map (d: d.value) defs);
  };

  # -- node builder ----------------------------------------------------------

  buildNode =
    {
      name,
      node,
      traits,
      allNodes,
      userArgs,
    }:
    let
      missing = builtins.filter (t: !(traits ? ${t})) node.traits;
      schema = builtins.addErrorContext "node '${name}' schema" node.schema;
      frameworkArgs = userArgs // {
        inherit name schema;
        nodes = lib.mapAttrs (_: n: { inherit (n) schema traits; }) allNodes;
      };
      traitModules = map (
        tName:
        builtins.addErrorContext "loading trait '${tName}'" (
          loadModule "trait:${tName}@${name}" traits.${tName}
        )
      ) node.traits;
      includeModules = lib.imap0 (
        i: m:
        builtins.addErrorContext "loading include[${toString i}]" (
          loadModule "include:${toString i}@${name}" m
        )
      ) node.includes;
    in
    lib.throwIf (missing != [ ]) "[nixy] node '${name}': unknown traits — ${toString missing}" {
      module = {
        config._module.args = frameworkArgs;
        imports = traitModules ++ includeModules;
      };
      inherit schema;
    };

  # -- core module -----------------------------------------------------------

  mkCore =
    { userArgs }:
    { config, ... }:
    let
      schemaOpts = toOptions "" config.schema;
      nodeType = lib.types.submodule {
        options = {
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
        builtins.addErrorContext "building node '${nodeName}'" (buildNode {
          name = nodeName;
          inherit node userArgs;
          traits = config.traits;
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
          type = lib.types.attrsOf lib.types.raw;
          default = { };
        };
        nodes = lib.mkOption {
          type = lib.types.lazyAttrsOf nodeType;
          default = { };
        };
        _result = lib.mkOption {
          type = deepMerge;
          internal = true;
        };
      };
      config._result.nodes = builtNodes;
    };

  # -- evaluation ------------------------------------------------------------

  excludeFn =
    if exclude == null then
      defaultExclude
    else if builtins.isFunction exclude then
      exclude
    else
      throw "[nixy] 'exclude' must be a function";

  resolved = lib.concatMap (resolveImport excludeFn) (lib.toList imports);

  evaluated = lib.evalModules {
    class = "nixy";
    modules = map loadFile resolved ++ [ (mkCore { userArgs = args; }) ];
    specialArgs = args // helpers // { inherit lib; };
  };

  result = evaluated.config._result;

in
result
// {
  inherit (evaluated) options;
  extend =
    extra:
    import ./eval.nix {
      inherit lib;
      imports = lib.toList imports ++ lib.toList (extra.imports or [ ]);
      args = args // (extra.args or { });
      exclude = extra.exclude or exclude;
    };
}

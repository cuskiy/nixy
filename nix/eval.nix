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
        throw "[nixy/scan] relative string path '${x}' not supported; use a path literal instead"
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

  # -- validation ------------------------------------------------------

  validName = s: builtins.match "[a-zA-Z_][a-zA-Z0-9_-]*" s != null;

  reservedAny = [
    "enable"
    "load"
  ];

  reservedFirst = [
    "system"
    "target"
    "extraModules"
    "instantiate"
  ];

  checkPath =
    tag: segs:
    let
      path = lib.concatStringsSep "." segs;
      top = builtins.head segs;
      badAny = lib.findFirst (s: builtins.elem s reservedAny) null segs;
      badName = lib.findFirst (s: !(validName s)) null segs;
    in
    lib.throwIf (badAny != null) "[nixy/${tag}] '${path}': '${badAny}' is reserved"
      (
        lib.throwIf (badName != null) "[nixy/${tag}] '${path}': invalid segment '${badName}'"
          (
            lib.throwIf (builtins.elem top reservedFirst)
              "[nixy/${tag}] '${path}': '${top}' is a host built-in"
              segs
          )
      );

  # -- schema ----------------------------------------------------------

  isOption = x: builtins.isAttrs x && (x._type or null) == "option";

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
            _ = checkPath "schema" (lib.splitString "." path);
          in
          [
            {
              inherit path;
              option = value;
            }
          ]
        else if builtins.isAttrs value then
          flattenSchema path value
        else
          throw "[nixy/schema] '${path}': expected option or attrset"
      ) attrs
    );

  # -- module tree type ------------------------------------------------

  moduleLeaf = lib.mkOptionType {
    name = "deferredModules";
    check = builtins.isList;
    merge =
      loc: defs:
      let
        badDefs = builtins.filter (d: !(builtins.isList d.value)) defs;
      in
      lib.throwIf (badDefs != [ ])
        "[nixy/modules] '${lib.showOption loc}': expected a list (use load = [ ... ])"
        (
          lib.concatMap (
            d:
            map (
              entry:
              if builtins.isFunction entry || builtins.isAttrs entry then
                lib.setDefaultModuleLocation "${d.file}, via ${lib.showOption loc}" entry
              else
                entry
            ) d.value
          ) defs
        );
  };

  moduleTree =
    let
      inner = lib.mkOptionType {
        name = "moduleTree";
        check = builtins.isAttrs;
        merge =
          loc: defs:
          let
            bad = builtins.filter (d: !(builtins.isAttrs d.value)) defs;
            hint =
              if builtins.any (d: builtins.isFunction d.value) bad then
                " (did you mean '${lib.concatStringsSep "." loc}.load = [ ... ]'?)"
              else
                "";
          in
          lib.throwIf (bad != [ ])
            "[nixy/modules] '${lib.concatStringsSep "." loc}': expected attrset${hint}"
            (
              let
                allKeys = lib.unique (lib.concatMap (d: builtins.attrNames d.value) defs);
              in
              lib.genAttrs allKeys (
                key:
                let
                  subs = lib.concatMap (
                    d: lib.optional (d.value ? ${key}) { inherit (d) file; value = d.value.${key}; }
                  ) defs;
                in
                if key == "load" then moduleLeaf.merge (loc ++ [ key ]) subs else inner.merge (loc ++ [ key ]) subs
              )
            );
      };
    in
    lib.mkOptionType {
      name = "moduleTree";
      check = builtins.isAttrs;
      merge = inner.merge;
    };

  collectIds =
    prefix: tree:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          path = if prefix == "" then name else "${prefix}.${name}";
        in
        if name == "load" then
          if prefix == "" then
            throw "[nixy/modules] 'load' cannot be a top-level key"
          else
            let
              _ = checkPath "modules" (lib.splitString "." prefix);
            in
            [ prefix ]
        else if builtins.isAttrs value then
          collectIds path value
        else
          throw "[nixy/modules] '${path}': unexpected ${builtins.typeOf value}"
      ) tree
    );

  # -- deep merge (for schema) -----------------------------------------

  deepMerge = lib.mkOptionType {
    name = "deepMerge";
    check = builtins.isAttrs;
    merge = _: defs: lib.foldl' lib.recursiveUpdate { } (map (d: d.value) defs);
  };

  # -- merged function (for perSystem) ---------------------------------

  mergedFn = lib.mkOptionType {
    name = "mergedFunction";
    check = builtins.isFunction;
    merge =
      _: defs: args:
      lib.foldl' lib.recursiveUpdate { } (map (d: d.value args) defs);
  };

  # -- host type tree --------------------------------------------------

  emptyNode = {
    opts = { };
    sub = { };
  };

  insertAt =
    node: segs: f:
    let
      h = builtins.head segs;
      t = builtins.tail segs;
    in
    if t == [ ] then
      f node h
    else
      let
        child = node.sub.${h} or emptyNode;
      in
      node // { sub = node.sub // { ${h} = insertAt child t f; }; };

  insertOpt = node: segs: opt: insertAt node segs (n: h: n // { opts = n.opts // { ${h} = opt; }; });

  insertEnable =
    node: segs: id:
    insertAt node segs (
      n: h:
      let
        child = n.sub.${h} or emptyNode;
      in
      n
      // {
        sub = n.sub // {
          ${h} = child // {
            opts = child.opts // {
              enable = lib.mkEnableOption id;
            };
          };
        };
      }
    );

  joinPath = prefix: n: if prefix == "" then n else "${prefix}.${n}";

  buildOpts =
    prefix: node:
    let
      clash = builtins.attrNames (builtins.intersectAttrs node.opts node.sub);
    in
    lib.throwIf (clash != [ ])
      "[nixy] cannot be both option and namespace: ${lib.concatMapStringsSep ", " (c: "'${joinPath prefix c}'") clash}"
      (
        node.opts
        // lib.mapAttrs (
          n: child:
          lib.mkOption {
            type = lib.types.submodule { options = buildOpts (joinPath prefix n) child; };
            default = { };
          }
        ) node.sub
      );

  builtinHostOpts = {
    system = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    target = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
    };
    instantiate = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      default = null;
    };
  };

  mkHostType =
    schemaEntries: moduleIds:
    let
      t0 = lib.foldl' (acc: e: insertOpt acc (lib.splitString "." e.path) e.option) emptyNode
        schemaEntries;
      t1 = lib.foldl' (acc: id: insertEnable acc (lib.splitString "." id) id) t0 moduleIds;
    in
    lib.types.submodule { options = builtinHostOpts // buildOpts "" t1; };

  # -- host build ------------------------------------------------------

  resolveTarget =
    host:
    if host.target != null then
      host.target
    else if host.system != null && lib.hasSuffix "-darwin" host.system then
      "darwin"
    else
      "nixos";

  cleanHost =
    host:
    removeAttrs host [
      "extraModules"
      "instantiate"
    ]
    // { target = resolveTarget host; };

  isEnabled =
    host: id: (lib.getAttrFromPath (lib.splitString "." id ++ [ "enable" ]) host) == true;

  buildHost =
    {
      name,
      host,
      moduleIds,
      allHosts,
      rawModules,
      targets,
      args,
    }:
    let
      target = resolveTarget host;
      active = builtins.filter (isEnabled host) moduleIds;
      payload = lib.concatMap (
        id: (lib.getAttrFromPath (lib.splitString "." id) rawModules).load
      ) active;
      inst =
        if host.instantiate != null then
          host.instantiate
        else
          let
            td = targets.${target} or null;
          in
          if td != null then
            td.instantiate
          else
            throw "[nixy/hosts] '${name}': unknown target '${target}'";
    in
    inst {
      system = host.system;
      specialArgs = {
        inherit name target;
        system = host.system;
        host = cleanHost host;
        hosts = lib.mapAttrs (_: cleanHost) allHosts;
      } // args;
      modules = payload ++ host.extraModules;
    };

  # -- check ------------------------------------------------------------

  fmtCheckDoc =
    {
      schemaEntries,
      moduleIds,
      hostNames,
    }:
    let
      fmtField =
        e:
        let
          type = e.option.type.description or e.option.type.name or "?";
          def =
            if !(e.option ? default) then
              "-"
            else if e.option.default == null then
              "`null`"
            else
              "`${builtins.toJSON e.option.default}`";
        in
        "| `${e.path}` | ${type} | ${def} |";
      n = builtins.length;
    in
    lib.concatStringsSep "\n" (
      [
        "# Schema"
        "> ${toString (n schemaEntries)} fields"
      ]
      ++ lib.optionals (schemaEntries != [ ]) [
        "| Field | Type | Default |"
        "|-------|---------|------|"
        (lib.concatMapStringsSep "\n" fmtField schemaEntries)
      ]
      ++ [
        ""
        "# Modules"
        "> ${toString (n moduleIds)}${lib.optionalString (moduleIds != [ ]) ": ${lib.concatStringsSep ", " moduleIds}"}"
        ""
        "# Hosts"
        "> ${toString (n hostNames)}${lib.optionalString (hostNames != [ ]) ": ${lib.concatStringsSep ", " hostNames}"}"
      ]
    );

  mkApp =
    nixpkgs: system: name: script:
    {
      type = "app";
      program = toString (
        nixpkgs.legacyPackages.${system}.writeShellScript "nixy-${name}" script
      );
    };

  # -- core module -----------------------------------------------------

  defaultSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  mkCore =
    { nixpkgs, args }:
    { config, ... }:
    let
      schemaEntries = flattenSchema "" config.schema;
      moduleIds = collectIds "" config.modules;
      hostType = mkHostType schemaEntries moduleIds;

      builtHosts = lib.mapAttrs (
        name: host:
        builtins.addErrorContext
          "while building host '${name}' (${host.system}, ${resolveTarget host})"
          (buildHost {
            inherit name host moduleIds args;
            allHosts = config.hosts;
            rawModules = config.modules;
            targets = config.targets;
          })
      ) config.hosts;

      hostsByTarget = lib.groupBy (n: resolveTarget config.hosts.${n}) (
        builtins.attrNames config.hosts
      );

      targetOutputs = lib.mapAttrs' (
        tgt: def:
        lib.nameValuePair def.output (lib.genAttrs (hostsByTarget.${tgt} or [ ]) (n: builtHosts.${n}))
      ) config.targets;

      rulesErrs = map (r: r.message) (builtins.filter (r: !r.assertion) config.rules);
      checked =
        lib.throwIf (rulesErrs != [ ])
          ("[nixy/rules]\n" + lib.concatMapStringsSep "\n" (e: "  - ${e}") rulesErrs)
          targetOutputs;

      perSystemResults = lib.genAttrs config.systems (
        system:
        config.perSystem (
          {
            inherit system lib;
            pkgs = nixpkgs.legacyPackages.${system};
            hosts = lib.mapAttrs (_: cleanHost) config.hosts;
          }
          // args
        )
      );

      mkPerSystemOutput =
        key:
        lib.filterAttrs (_: v: v != { }) (
          lib.genAttrs config.systems (s: perSystemResults.${s}.${key} or { })
        );

      formatter = lib.genAttrs config.systems (
        system:
        let
          ps = perSystemResults.${system};
        in
        if ps ? formatter then ps.formatter else nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );

      checkDoc = fmtCheckDoc {
        inherit schemaEntries moduleIds;
        hostNames = builtins.attrNames config.hosts;
      };

      apps = lib.genAttrs config.systems (
        system:
        (perSystemResults.${system}.apps or { })
        // {
          check = mkApp nixpkgs system "check" "cat <<'__NIXY_CHECK_EOF__'\n${checkDoc}\n__NIXY_CHECK_EOF__";
        }
      );
    in
    {
      _file = "<nixy/core>";

      options = {
        systems = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = defaultSystems;
          description = "Systems for perSystem outputs.";
        };
        perSystem = lib.mkOption {
          type = mergedFn;
          default = _: { };
          description = "Per-system outputs. Multiple definitions are deep-merged.";
        };
        schema = lib.mkOption {
          type = deepMerge;
          default = { };
        };
        modules = lib.mkOption {
          type = moduleTree;
          default = { };
        };
        hosts = lib.mkOption {
          type = lib.types.attrsOf hostType;
          default = { };
        };
        targets = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                instantiate = lib.mkOption { type = lib.types.raw; };
                output = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = { };
        };
        rules = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                assertion = lib.mkOption { type = lib.types.bool; };
                message = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = [ ];
        };
        flake = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
          };
          default = { };
        };
      };

      config = {
        targets.nixos = {
          instantiate =
            {
              modules,
              specialArgs,
              system ? null,
            }:
            lib.nixosSystem (
              { inherit modules specialArgs; } // lib.optionalAttrs (system != null) { inherit system; }
            );
          output = "nixosConfigurations";
        };

        flake = lib.mapAttrs (_: lib.mkDefault) (
          checked
          // {
            inherit formatter apps;
          }
          // lib.genAttrs [
            "packages"
            "devShells"
            "checks"
            "legacyPackages"
          ] mkPerSystemOutput
        );
      };
    };
in
{
  meta.version = "0.5.0";
  inherit helpers;

  eval =
    {
      nixpkgs,
      imports,
      args,
      exclude,
    }:
    let
      excludeFn = if exclude != null then exclude else defaultExclude;
      resolved = lib.concatMap (resolveImport excludeFn) (lib.toList imports);
      core = mkCore { inherit nixpkgs args; };
      evaluated = lib.evalModules {
        class = "nixy";
        modules = map loadFile resolved ++ [ core ];
        specialArgs =
          {
            inherit lib nixpkgs;
            pkgsFor = system: nixpkgs.legacyPackages.${system};
          }
          // helpers
          // args;
      };
    in
    lib.filterAttrs (_: v: v != { }) evaluated.config.flake;
}

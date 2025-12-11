{
  description = "Assorted nix scripts and bits";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nurpkgs.url = "github:josh/nurpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nurpkgs,
    }:
    let
      internal-inputs = builtins.mapAttrs (
        _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
      ) (builtins.fromJSON (builtins.readFile ./internal/flake.lock)).nodes;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      inherit (nixpkgs) lib;

      importNixpkgs =
        nixpkgs: system:
        import nixpkgs {
          system = "${system}";
          overlays = [
            nurpkgs.overlays.default
            self.overlays.default
          ];
          config.allowUnfreePredicate = _pkg: true;
        };

      eachSystem = lib.genAttrs systems;

      mkPackages =
        pkgs:
        let
          collectPkgsByName =
            attrs:
            lib.attrsets.foldlAttrs (
              pkgs: _name: pkg:
              if (lib.attrsets.isDerivation pkg) && pkg.meta.available then
                pkgs // { ${lib.strings.getName pkg.name} = pkg; }
              else
                pkgs
            ) { } attrs;
        in
        lib.attrsets.foldlAttrs (
          pkgs: name: pkg:
          if (builtins.isAttrs pkg) && (pkg.recurseForDerivations or false) then
            pkgs // (collectPkgsByName pkg)
          else if (lib.attrsets.isDerivation pkg) && pkg.meta.available then
            pkgs // { ${name} = pkg; }
          else
            pkgs
        ) { } pkgs.nixbits;

      mkChecks =
        name: pkgs:
        let
          buildCheckPkg = pkg: pkgs.runCommand "${pkg.name}-${name}-build" { env.PKG = pkg; } "touch $out";
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
        in
        lib.attrsets.concatMapAttrs (
          pkgName: pkg:
          if (builtins.hasAttr "tests" pkg) then
            {
              "${pkgName}-${name}-build" = buildCheckPkg pkg;
            }
            // (addAttrsetPrefix "${pkgName}-${name}-tests-" pkg.tests)
          else
            { "${pkgName}-${name}-build" = buildCheckPkg pkg; }
        ) (mkPackages pkgs);

      treefmt-nix = eachSystem (system: import ./internal/treefmt.nix nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = import ./overlay.nix;

      packages = eachSystem (system: mkPackages (importNixpkgs nixpkgs system));

      nixosModules = {
        healthchecks = ./modules/healthchecks.nix;
      };

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);

      checks = eachSystem (
        system:
        {
          formatting = treefmt-nix.${system}.check self;
        }
        // (mkChecks "stable" (importNixpkgs internal-inputs.nixpkgs-stable system))
        // (mkChecks "unstable" (importNixpkgs internal-inputs.nixpkgs-unstable system))
      );
    };
}

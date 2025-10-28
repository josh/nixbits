{
  description = "Assorted nix scripts and bits";

  nixConfig = {
    extra-substituters = [
      "https://josh.cachix.org"
    ];
    extra-trusted-public-keys = [
      "josh.cachix.org-1:qc8IeYlP361V9CSsSVugxn3o3ZQ6w/9dqoORjm0cbXk="
    ];
  };

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
      inherit (nixpkgs) lib;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = lib.genAttrs systems;
      eachPkgs =
        fn:
        eachSystem (
          system:
          fn (
            import nixpkgs {
              system = "${system}";
              overlays = [
                nurpkgs.overlays.default
                self.overlays.default
              ];
              config.allowUnfreePredicate = _pkg: true;
            }
          )
        );

      treefmt-nix = eachPkgs (pkgs: import ./internal/treefmt.nix pkgs);
    in
    {
      overlays.default = import ./overlay.nix;

      packages = eachPkgs (
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

          collectPkgs =
            attrs:
            lib.attrsets.foldlAttrs (
              pkgs: name: pkg:
              if (builtins.isAttrs pkg) && (pkg.recurseForDerivations or false) then
                pkgs // (collectPkgsByName pkg)
              else if (lib.attrsets.isDerivation pkg) && pkg.meta.available then
                pkgs // { ${name} = pkg; }
              else
                pkgs
            ) { } attrs;
        in
        collectPkgs pkgs.nixbits
      );

      nixosModules = {
        healthchecks = ./modules/healthchecks.nix;
      };

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);

      checks = eachPkgs (
        pkgs:
        let
          inherit (pkgs) system;
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          buildPkg = pkg: pkgs.runCommand "${pkg.name}-build" { env.PKG = pkg; } "touch $out";
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              (
                {
                  "${pkgName}-build" = buildPkg pkg;
                }
                // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests)
              )
            else
              {
                "${pkgName}-build" = buildPkg pkg;
              }
          ) self.packages.${system};
        in
        {
          formatting = treefmt-nix.${system}.check self;
        }
        // localTests
      );
    };
}

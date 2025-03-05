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
          uniqueMergeAttrs = lib.misc.mergeAttrsWithFunc (
            a: b: if a == b && a.meta == b.meta then a else builtins.throw "duplicate pkgs: ${a}"
          );
          collectPkgs =
            attrs:
            lib.lists.foldl' uniqueMergeAttrs { } (
              builtins.map (
                value:
                if (lib.attrsets.isDerivation value) && value.meta.available then
                  { "${lib.strings.getName value.meta.name}" = value; }
                else if (builtins.isAttrs value) && (value.recurseForDerivations or false) then
                  collectPkgs value
                else
                  { }
              ) (builtins.attrValues attrs)
            );
        in
        collectPkgs pkgs.nixbits
      );

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);

      checks = eachSystem (
        system:
        let
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              (
                {
                  "${pkgName}-build" = pkg;
                }
                // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests)
              )
            else
              {
                "${pkgName}-build" = pkg;
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

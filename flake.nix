{
  description = "Assorted nix scripts and bits";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = lib.genAttrs systems;
      eachPkgs =
        fn: eachSystem (system: fn (nixpkgs.legacyPackages.${system}.extend self.overlays.default));

      treefmt-nix = eachPkgs (pkgs: import ./internal/treefmt.nix pkgs);
    in
    {
      overlays.default = import ./overlay.nix;

      packages = eachPkgs (
        pkgs:
        let
          isAvailable = _: pkg: pkg.meta.available;
        in
        lib.attrsets.filterAttrs isAvailable pkgs.nixbits
      );

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);

      checks = eachSystem (
        system:
        let
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              ({ "${pkgName}-build" = pkg; } // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests))
            else
              { "${pkgName}-build" = pkg; }
          ) self.packages.${system};
        in
        {
          formatting = treefmt-nix.${system}.check self;
        }
        // localTests
      );
    };
}

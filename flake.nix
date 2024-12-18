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
      eachPkgs = fn: eachSystem (system: fn nixpkgs.legacyPackages.${system});

      internal-inputs = builtins.mapAttrs (
        _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
      ) (builtins.fromJSON (builtins.readFile ./internal/flake.lock)).nodes;

      treefmtEval = eachPkgs (pkgs: internal-inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      packages = eachPkgs (pkgs: {
        inherit (pkgs) hello;
      });

      formatter = eachSystem (system: treefmtEval.${system}.config.build.wrapper);

      checks = eachSystem (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}

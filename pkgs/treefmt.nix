{
  lib,
  pkgs,
  symlinkJoin,
  # keep-sorted start
  actionlint,
  deadnix,
  isort,
  keep-sorted,
  nixfmt-rfc-style,
  nodePackages,
  ruff,
  shellcheck,
  shfmt,
  sqlfluff,
  statix,
  stylua,
  taplo,
  ty,
# keep-sorted end
}:
let
  internal-inputs = builtins.mapAttrs (
    _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
  ) (builtins.fromJSON (builtins.readFile ./../internal/flake.lock)).nodes;

  treefmt-nix = import internal-inputs.treefmt-nix;

  treefmt = treefmt-nix.mkWrapper pkgs {
    projectRootFile = ".git/config";
    # keep-sorted start
    programs.actionlint.enable = true;
    programs.clang-format.enable = true;
    programs.deadnix.enable = true;
    programs.gofmt.enable = true;
    programs.isort.enable = true;
    programs.just.enable = true;
    programs.keep-sorted.enable = true;
    programs.mypy.enable = true;
    programs.nixfmt.enable = true;
    programs.prettier.enable = true;
    programs.ruff-check.enable = true;
    programs.ruff-format.enable = true;
    programs.shellcheck.enable = true;
    programs.shfmt.enable = true;
    programs.sqlfluff.enable = true;
    programs.statix.enable = true;
    programs.stylua.enable = true;
    programs.swift-format.enable = true;
    programs.taplo.enable = true;
    # programs.ty.enable = true;
    # keep-sorted end
  };
in
symlinkJoin {
  name = "treefmt";
  paths = [
    # keep-sorted start
    actionlint
    deadnix
    isort
    keep-sorted
    nixfmt-rfc-style
    ruff
    shellcheck
    shfmt
    sqlfluff
    statix
    stylua
    taplo
    treefmt
    ty
    # keep-sorted end
  ];
  postBuild = ''
    find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete

    # Prettier's bin directory is weird
    ln -s ${lib.getExe nodePackages.prettier} $out/bin/prettier

    # delete everything but bin/
    for dir in $out/*; do
      if [ "$dir" != "$out/bin" ]; then
        rm -rf "$dir"
      fi
    done
  '';
  meta = {
    inherit (treefmt.meta)
      description
      homepage
      mainProgram
      platforms
      ;
  };
}

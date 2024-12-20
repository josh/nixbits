{ pkgs }:
let
  internal-inputs = builtins.mapAttrs (
    _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
  ) (builtins.fromJSON (builtins.readFile ./../internal/flake.lock)).nodes;

  treefmt-nix = import internal-inputs.treefmt-nix;
in
treefmt-nix.mkWrapper pkgs {
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
  # keep-sorted end
}

pkgs:
let
  internal-inputs = builtins.mapAttrs (
    _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
  ) (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes;
  treefmtEval = internal-inputs.treefmt-nix.lib.evalModule pkgs treefmtConfig;

  treefmtConfig = {
    projectRootFile = "flake.nix";
    programs.actionlint.enable = true;
    programs.deadnix.enable = true;
    programs.nixfmt.enable = true;
    programs.prettier.enable = true;
    programs.shellcheck.enable = true;
    programs.shfmt.enable = true;
    programs.statix.enable = true;
    programs.taplo.enable = true;
  };
in
treefmtEval.config.build

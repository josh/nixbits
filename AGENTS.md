# Agents Guide

## Setup

If `nix` is not installed, use the Determinate Systems installer:

```sh
$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
$ . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Ensure flake inputs are downloaded before running in an offline sandbox:

```sh
$ nix flake archive
$ nix flake archive ./internal/
```

## Testing

```sh
$ nix flake check --accept-flake-config --show-trace --print-build-logs --keep-going
```

These flags will give you the most verbose output for debugging. When running in an offline sandbox, you should append `--offline`.

This full check can take quite a while. If your change doesn't impact the entire repository, try building only the specific package you're working on instead, using verbose flags:

```sh
$ nix build --accept-flake-config --show-trace --print-build-logs .#yourPackageName
```

## Formatting

`nix flake check` will also check if source files are formatted correctly. If there is a formatting issue, run `nix fmt` to fix it.

## Packages

Packages defined under `pkgs/` are automatically exposed in the flake's package set under their filename. There are two exceptions:

- A file evaluating to an attrset with `recurseForDerivations` (currently only `pkgs/darwin.nix`) has its members exposed under their derivation names, e.g. `nix build .#open-impure-darwin` for `darwin.open`.
- Packages whose `meta.available` is false on the current system are omitted from `packages` and `checks` entirely.

`overlays.default` is not self-contained. It expects `nurpkgs.overlays.default` (providing `nur`) and `overlays.wrappers` (providing `wlibEvalPackage`, from [nix-wrapper-modules](https://github.com/nix-community/nix-wrapper-modules)) to be applied first.

## Modules

`modules/` holds two unrelated kinds of module. NixOS modules are listed by hand in `modules/default.nix` and `nixosModules`; [nix-wrapper-modules](https://github.com/nix-community/nix-wrapper-modules) wrapper modules (currently `modules/helix-wrapper.nix`) are listed in neither, and are imported directly by the package that evaluates them. The rest of this section applies only to the NixOS modules.

NixOS modules under `modules/` are exported as `nixosModules.*` but are NOT evaluated by `nix flake check` — a module that fails to evaluate still passes the full check. After changing a module, evaluate it against a minimal system:

```sh
$ nix eval --impure --expr 'let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    nixpkgs = builtins.getFlake (builtins.flakeRefToString lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked);
    eval = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./modules/default.nix
        {
          boot.loader.grub.enable = false;
          fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
          system.stateVersion = nixpkgs.lib.trivial.release;
          # enable the module under test here
        }
      ];
    };
  in eval.config.system.build.toplevel.drvPath'
```

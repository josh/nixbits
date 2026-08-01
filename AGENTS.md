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

## Modules

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

{
  lib,
  stdenvNoCC,
  runtimeShell,
  lndir,
  makeWrapper,
  gh,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  pname = "gh";
  inherit (gh) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];
  makeWrapperArgs =
    (lib.lists.optionals stdenvNoCC.hostPlatform.isDarwin [
      "--set"
      "GH_CONFIG_DIR"
      "${nixbits.gh-config-dir}"
    ])
    ++ [
      "--set"
      "GH_NO_UPDATE_NOTIFIER"
      "1"
      "--set"
      "GH_NO_EXTENSION_UPDATE_NOTIFIER"
      "1"
    ];

  postInstallText = ''
    #!${runtimeShell}
    set -o errexit
    source "${nixbits.xtrace}/share/bash/xtrace.bash"
    export PATH="${builtins.placeholder "out"}/bin:$PATH"
    x-silent gh auth status --hostname github.com
  '';

  buildCommand = ''
    mkdir $out
    lndir -silent ${gh} $out

    rm $out/bin/gh
    makeWrapper ${gh}/bin/gh $out/bin/gh "''${makeWrapperArgs[@]}"

    mkdir -p $out/share/nix/hooks/post-install.d
    echo -n "$postInstallText" >"$out/share/nix/hooks/post-install.d/gh"
    chmod +x "$out/share/nix/hooks/post-install.d/gh"
  '';

  inherit (gh) meta;
}

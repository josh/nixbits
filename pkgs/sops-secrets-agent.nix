{
  lib,
  stdenvNoCC,
  writeText,
  nixbits,
  nur,
  runtimeShell,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "sops-secrets-agent";

  __structuredAttrs = true;

  manifest = nixbits.sops-manifest;
  ageIdentity = null;
  agePackage = nixbits.age;
  logPath =
    if finalAttrs.manifest.homeDirectory == null then
      null
    else
      "${finalAttrs.manifest.homeDirectory}/Library/Logs/sops-nix.log";

  job = {
    Label = "com.github.josh.nixbits.sops-secrets";
    ProgramArguments = [
      "${nur.repos.josh.sops-install-secrets}/bin/sops-install-secrets"
      "-ignore-passwd"
      "${finalAttrs.manifest}"
    ];
    EnvironmentVariables = {
      PATH = "${finalAttrs.agePackage}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    }
    // (lib.attrsets.optionalAttrs (finalAttrs.ageIdentity != null) {
      SOPS_AGE_KEY_CMD = lib.meta.getExe finalAttrs.ageIdentity;
    });
    RunAtLoad = true;
    KeepAlive = false;
  }
  // (lib.attrsets.optionalAttrs (finalAttrs.logPath != null) {
    StandardOutPath = finalAttrs.logPath;
    StandardErrorPath = finalAttrs.logPath;
  });

  launchAgent = writeText "${finalAttrs.job.Label}.plist" (
    lib.generators.toPlist { escape = true; } finalAttrs.job
  );

  preInstallHook = writeText "sops-secrets-agent-pre-install-hook" ''
    #!${runtimeShell}
    ${nixbits.xtrace}/bin/x -s -- ${nur.repos.josh.sops-install-secrets}/bin/sops-install-secrets -check-mode=manifest ${finalAttrs.manifest}
  '';

  buildCommand = ''
    mkdir -p $out/Library/LaunchAgents
    cp "$launchAgent" "$out/Library/LaunchAgents/${finalAttrs.job.Label}.plist"

    mkdir -p $out/share/nix/hooks/pre-install.d
    cp "$preInstallHook" $out/share/nix/hooks/pre-install.d/sops-secrets-agent
    chmod +x $out/share/nix/hooks/pre-install.d/sops-secrets-agent
  '';

  meta = {
    description = "Materialize sops secrets at login with a launchd user agent";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
})

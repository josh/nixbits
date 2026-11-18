{
  lib,
  replaceVars,
  nixbits,
  jujutsuWrapper ? nixbits.jujutsu,
  jujutsu-clone ? jujutsuWrapper.configuration.commands.jj-clone,
}:
replaceVars ./zp.zsh {
  jj = lib.getExe jujutsuWrapper;
  git = lib.getExe jujutsuWrapper.configuration.gitWrapper;
  clone = lib.getExe jujutsu-clone;
}

if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
end

for file in @out@/conf.d/*.fish
  source $file
end

set --global fish_greeting

set --export PATH $PATH @fish-path@/bin

status is-login; and begin
  # Login shell initialization
  @loginShellInit@
end

status is-interactive; and begin
  source @direnv-init@

  # Interactive shell initialization
  @interactiveShellInit@
end

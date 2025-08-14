if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
end

if test -d "/nix/var/nix/profiles/default/bin"
  fish_add_path --prepend --global "/nix/var/nix/profiles/default/bin"
end
if test -d "$HOME/.local/state/nix/profile/bin"
  fish_add_path --prepend --global "$HOME/.local/state/nix/profile/bin"
else if test -d "$HOME/.nix-profile/bin"
  fish_add_path --prepend --global "$HOME/.nix-profile/bin"
end
fish_add_path --prepend --global @fish-path@/bin

for file in @out@/conf.d/*.fish
  source $file
end

set --global fish_greeting

status is-login; and begin
  # Login shell initialization
  @loginShellInit@
end

status is-interactive; and begin
  source @direnv-init@

  # Interactive shell initialization
  @interactiveShellInit@
end

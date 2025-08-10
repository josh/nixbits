if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
end

for file in @out@/conf.d/*.fish
  source $file
end

set -g fish_greeting

set --export PATH $PATH @fish-path@/bin

status is-login; and begin
  # Login shell initialization
end

status is-interactive; and begin
  # Interactive shell initialization
  source @direnv-init@
end

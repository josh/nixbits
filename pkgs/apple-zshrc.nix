{ writeText }:
# Captured from macOS 27.2.1 (26B8132). To refresh, run from the repository root:
#   install -m 0644 /System/Library/Templates/Data/private/etc/zshrc pkgs/apple-zshrc/zshrc
#   sw_vers -productVersion
#   sw_vers -buildVersion
# Update the version and build above to match.
writeText "apple-zshrc" (builtins.readFile ./apple-zshrc/zshrc)

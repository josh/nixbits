set -o xtrace
xcrun simctl delete unavailable
rm -rf "$HOME/Library/Developer/Xcode/DerivedData"

#!/bin/zsh
# Stops vorssaint-stumm and removes its LaunchAgent. The folder itself stays.
label=com.bencodex.vorssaint-stumm
launchctl bootout gui/$(id -u)/$label 2>/dev/null || true
rm -f ~/Library/LaunchAgents/$label.plist
echo "vorssaint-stumm removed"

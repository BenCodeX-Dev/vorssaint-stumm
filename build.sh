#!/bin/zsh
# Builds vorssaint-stumm and (re)loads its LaunchAgent.
set -e
cd "${0:A:h}"
label=com.bencodex.vorssaint-stumm
agent=~/Library/LaunchAgents/$label.plist
swiftc -O main.swift -o vorssaint-stumm
# The agent needs absolute paths, so the folder this script lives in is filled in here.
mkdir -p ~/Library/LaunchAgents
sed "s|__DIR__|$PWD|g" $label.plist > $agent
launchctl bootout gui/$(id -u)/$label 2>/dev/null || true
launchctl bootstrap gui/$(id -u) $agent
echo "vorssaint-stumm running"

#!/bin/bash
# Checks the story-world data file (Assets.xcassets/worlds.dataset/worlds.json) with the app's own loader rules.
# On Linux, point STUBS at a folder with a CoreGraphics module (Foundation already has CGFloat there).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${PKG:-$HERE/../../HopQuest.swiftpm}"
OUT="${TMPDIR:-/tmp}/hopquest-world-tests"
EXTRA=()
if [ -n "${STUBS:-}" ]; then EXTRA=(-I "$STUBS"); fi
swiftc -O "${EXTRA[@]}" "$PKG/Models/WorldData.swift" "$PKG/Models/Chapters.swift" "$HERE/main.swift" -o "$OUT"
"$OUT" "$PKG/Assets.xcassets/worlds.dataset/worlds.json"

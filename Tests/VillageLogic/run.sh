#!/bin/bash
# Compiles Hop Village's pure-logic files with a small test runner and runs it.
# Works on macOS (Xcode command-line tools) or Linux (any Swift 5.9+ toolchain).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${PKG:-$HERE/../../HopQuest.swiftpm}"
OUT="${TMPDIR:-/tmp}/hopquest-village-tests"
swiftc -O \
  "$PKG/Models/VillageMap.swift" "$PKG/Models/VillageMapData.swift" "$PKG/Models/VillageBuilding.swift" \
  "$PKG/Models/VillageNPC.swift" "$PKG/Models/VillageInteraction.swift" "$PKG/Models/VillageSaveState.swift" \
  "$PKG/Scenes/VillageCollisionSystem.swift" "$PKG/Scenes/VillagePlayerController.swift" \
  "$HERE/main.swift" -o "$OUT"
"$OUT"

#!/bin/bash
# Compiles the Reading Nook and Math Market logic with a test runner and runs it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${PKG:-$HERE/../../HopQuest.swiftpm}"
OUT="${TMPDIR:-/tmp}/hopquest-learn-tests"
FILES=("$PKG/Models/Reading.swift")
[ -f "$PKG/Models/MathMarket.swift" ] && FILES+=("$PKG/Models/MathMarket.swift")
[ -f "$PKG/Models/Garden.swift" ] && FILES+=("$PKG/Models/Garden.swift")
[ -f "$PKG/Models/Story.swift" ] && FILES+=("$PKG/Models/Story.swift")
swiftc -O "${FILES[@]}" "$HERE/main.swift" -o "$OUT"
"$OUT"

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
[ -f "$PKG/Models/ScienceLab.swift" ] && FILES+=("$PKG/Models/ScienceLab.swift")
[ -f "$PKG/Models/Music.swift" ] && FILES+=("$PKG/Models/Music.swift")
[ -f "$PKG/Models/Writing.swift" ] && FILES+=("$PKG/Models/Writing.swift")
[ -f "$PKG/Models/ClockTower.swift" ] && FILES+=("$PKG/Models/ClockTower.swift")
[ -f "$PKG/Models/WorldTour.swift" ] && FILES+=("$PKG/Models/WorldTour.swift")
[ -f "$PKG/Models/Milestones.swift" ] && FILES+=("$PKG/Models/Milestones.swift")
[ -f "$PKG/Models/QuickGame.swift" ] && FILES+=("$PKG/Models/QuickGame.swift")
[ -f "$PKG/Shared/WidgetShared.swift" ] && FILES+=("$PKG/Shared/WidgetShared.swift")
[ -f "$PKG/Shared/HopWords.swift" ] && FILES+=("$PKG/Shared/HopWords.swift")
[ -f "$PKG/Models/QuizPlace.swift" ] && FILES+=("$PKG/Models/QuizPlace.swift")
[ -f "$PKG/Models/MorePlaces.swift" ] && FILES+=("$PKG/Models/MorePlaces.swift")
[ -f "$PKG/Models/PlayExtras.swift" ] && FILES+=("$PKG/Models/PlayExtras.swift")
[ -f "$PKG/Models/StoryMaker.swift" ] && FILES+=("$PKG/Models/StoryMaker.swift")
[ -f "$PKG/Models/Badges.swift" ] && FILES+=("$PKG/Models/Badges.swift")
[ -f "$PKG/Models/Spanish.swift" ] && FILES+=("$PKG/Models/Spanish.swift")
[ -f "$PKG/Models/SpanishMore.swift" ] && FILES+=("$PKG/Models/SpanishMore.swift")
swiftc -O "${FILES[@]}" "$HERE/main.swift" -o "$OUT"
"$OUT"

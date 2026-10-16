#!/bin/bash
# Compiles Code Club's robot language and the Machine Workshop models with a test runner and runs it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${PKG:-$HERE/../../HopQuest.swiftpm}"
OUT="${TMPDIR:-/tmp}/hopquest-robotlab-tests"
swiftc -O "$PKG"/Models/RobotCode.swift "$HERE/main.swift" -o "$OUT"
"$OUT"

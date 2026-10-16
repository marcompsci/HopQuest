#!/bin/bash
# Compiles the Coding Lab engine (MiniPython + lessons) with a test runner and runs it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${PKG:-$HERE/../../HopQuest.swiftpm}"
OUT="${TMPDIR:-/tmp}/hopquest-codelab-tests"
swiftc -O "$PKG"/Models/CodeLab/*.swift "$HERE/main.swift" -o "$OUT"
"$OUT"

#!/bin/bash
# Runs every HopQuest test suite. Works on macOS (Xcode command-line tools) and Linux (Swift 5.9+).
# Exits non-zero if ANY suite fails or can't run: a skipped suite is never reported as passed.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PKG="${PKG:-$ROOT/HopQuest.swiftpm}"
failed=()
run() {
  local name="$1"; shift
  echo "::group::$name"
  if "$@"; then echo "PASS  $name"; else echo "FAIL  $name"; failed+=("$name"); fi
  echo "::endgroup::"
}
run "Village logic"   bash "$ROOT/Tests/VillageLogic/run.sh"
run "Coding Lab"      bash "$ROOT/Tests/CodeLab/run.sh"
run "Robot Lab"       bash "$ROOT/Tests/RobotLab/run.sh"
run "Learn + Story"   bash "$ROOT/Tests/Learn/run.sh"
run "Worlds data"     bash "$ROOT/Tests/Worlds/run.sh"
run "Fort levels"     python3 "$ROOT/Tests/FortLevels/check_levels.py"
echo
if [ ${#failed[@]} -eq 0 ]; then echo "ALL TEST SUITES PASSED"; exit 0; fi
echo "FAILED: ${failed[*]}"; exit 1

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_VERSION="${EXPECTED_GODOT_VERSION:-4.7.stable.official.5b4e0cb0f}"

if [[ -z "${GODOT_BIN:-}" ]]; then
	for candidate in godot4 godot /Applications/Godot.app/Contents/MacOS/Godot; do
		if command -v "$candidate" >/dev/null 2>&1; then
			GODOT_BIN="$(command -v "$candidate")"
			break
		fi
	done
fi

GODOT_BIN="${GODOT_BIN:-}"

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "Godot executable not found: $GODOT_BIN" >&2
	exit 69
fi

ACTUAL_VERSION="$($GODOT_BIN --version | tr -d '[:space:]')"
if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
	echo "Expected Godot $EXPECTED_VERSION, found $ACTUAL_VERSION" >&2
	exit 69
fi

run_godot() {
	local output
	if ! output="$("$GODOT_BIN" "$@" 2>&1)"; then
		printf '%s\n' "$output"
		return 1
	fi
	printf '%s\n' "$output"
	if grep -Eq 'SCRIPT ERROR:|(^|[^A-Z])ERROR:' <<<"$output"; then
		echo "Godot reported a script or runtime error." >&2
		return 1
	fi
}

echo "[1/7] Importing the addon test project"
run_godot --headless --editor --path "$ROOT" --quit

echo "[2/7] Verifying party lifecycle behavior"
run_godot --headless --path "$ROOT" --script res://tests/party_session_test.gd

echo "[3/7] Verifying per-device input behavior"
run_godot --headless --path "$ROOT" --script res://tests/input_router_test.gd

echo "[4/7] Verifying headless lobby behavior"
run_godot --headless --path "$ROOT" --script res://tests/party_lobby_controller_test.gd

echo "[5/7] Verifying lobby presentation"
run_godot --headless --path "$ROOT" --script res://tests/party_lobby_view_test.gd

echo "[6/7] Verifying lobby interaction flow"
run_godot --headless --path "$ROOT" --script res://tests/party_lobby_test.gd

echo "[7/7] Booting the example project"
run_godot --headless --path "$ROOT" --quit-after 2

echo "Godot Couch Party verification passed."

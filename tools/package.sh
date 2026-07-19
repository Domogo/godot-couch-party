#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/addons/couch_party/VERSION")"
OUTPUT_DIR="${1:-$ROOT/artifacts}"
OUTPUT="$OUTPUT_DIR/godot-couch-party-$VERSION.zip"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT"
(
	cd "$ROOT"
	zip -qr "$OUTPUT" addons/couch_party
)

echo "$OUTPUT"

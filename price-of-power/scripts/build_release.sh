#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$repo_root/build"
mkdir -p "$build_dir"

godot --headless --path "$repo_root/godot" --import
godot --headless --path "$repo_root/godot" --script res://tests/test_runner.gd
godot --headless --path "$repo_root/godot" --export-pack "Linux" "$build_dir/price-of-power.pck"

printf 'Built %s\n' "$build_dir/price-of-power.pck"

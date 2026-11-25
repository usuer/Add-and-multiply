#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$repo_root/build"
mkdir -p "$build_dir"

godot --headless --path "$repo_root/godot" --import
godot --headless --path "$repo_root/godot" --script res://tests/test_runner.gd
godot --headless --path "$repo_root/godot" --script res://tests/ui_layout_test.gd
godot --headless --path "$repo_root/godot" --export-pack "Linux" "$build_dir/price-of-power.pck"

printf 'Built %s\n' "$build_dir/price-of-power.pck"

windows_exe="$build_dir/Price-of-Power.exe"
if godot --headless --path "$repo_root/godot" --export-release "Windows" "$windows_exe"; then
  windows_pck="$build_dir/Price-of-Power.pck"
  readme="$build_dir/README-RU.txt"
  printf '%s\n' \
    'ЦЕНА ВЛАСТИ — WINDOWS' \
    '' \
    'Распакуйте архив целиком. Оставьте EXE и PCK рядом и запустите EXE.' \
    'Требуется 64-битная Windows 10/11. Интернет не нужен.' > "$readme"
  (
    cd "$build_dir"
    zip -j -9 Price-of-Power-Windows.zip Price-of-Power.exe Price-of-Power.pck README-RU.txt
  )
  printf 'Built %s\n' "$build_dir/Price-of-Power-Windows.zip"
else
  printf '%s\n' 'Windows EXE skipped: install matching Godot export templates.' >&2
fi

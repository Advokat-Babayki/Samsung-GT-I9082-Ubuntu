#!/usr/bin/env bash
# Apply the device tree's AOSP 5.1 patches to the source tree.
# Patches live in device/samsung/i9082/PATCHES and are named by project path
# with underscores instead of slashes (frameworks_base -> frameworks/base).
set -uo pipefail

TREE="${I9082_TREE:-$HOME/i9082-ut}"
PATCH_DIR="$TREE/device/samsung/i9082/PATCHES"

[ -d "$PATCH_DIR" ] || { echo "no $PATCH_DIR - run sync first"; exit 1; }
cd "$TREE"

for patch in "$PATCH_DIR"/*.patch; do
  name=$(basename "$patch" .patch)
  dir=${name//_//}
  if [ ! -d "$dir" ]; then
    echo "SKIP $name (no $dir)"
    continue
  fi
  if git -C "$dir" apply --check "$patch" 2>/dev/null; then
    git -C "$dir" apply "$patch" && echo "OK   $name"
  elif git -C "$dir" apply --3way "$patch" 2>/dev/null; then
    echo "3WAY $name"
  else
    echo "FAIL $name (already applied or needs manual fix)"
  fi
done

#!/usr/bin/env bash
# Flash and install the port on the phone.
#
#   scripts/install.sh twrp    # phone in download mode: write TWRP + boot.img
#   scripts/install.sh system  # phone in TWRP recovery: install rootfs + android container
#
# No fastboot on this device: everything goes through heimdall / adb.
set -euo pipefail

TREE="${I9082_TREE:-$HOME/i9082-ut}"
REFS="$TREE/refs"
OUT="$TREE/out/target/product/i9082"

TWRP="$REFS/twrp-3.0.2-0-i9082.img"
ROOTFS="$REFS/vivid-preinstalled-touch-armhf.tar.gz"
SYSTEM="${SYSTEM:-$OUT/system.img}"
BOOT="${BOOT:-$OUT/boot.img}"
ROOTSTOCK="$TREE/tool-rootstock/rootstock-touch-install"

case "${1:-}" in
  twrp)
    [ -e "$TWRP" ] || { echo "missing $TWRP"; exit 1; }
    echo "Put the phone into download mode: Vol- + Home + Power, then Vol+."
    read -r -p "Press Enter when ready... " _
    heimdall flash --RECOVERY "$TWRP" --BOOT "$BOOT"
    echo "Phone reboots into TWRP."
    ;;

  system)
    for f in "$ROOTFS" "$SYSTEM" "$ROOTSTOCK"; do
      [ -e "$f" ] || { echo "missing $f"; exit 1; }
    done
    # rootstock demands make_ext4fs even though it is only used for sparse
    # images; ours is a raw ext4 image, so that branch never runs.
    # It also stages the rootfs tarball in /recovery, which does not exist in
    # TWRP; stage it on /data instead.
    sed -e 's/\[ ! \$(which make_ext4fs) \] || //' \
        -e 's|/recovery/|/data/rootstock/|g' \
        -e 's|/recovery\$|/data/rootstock|g' \
        "$ROOTSTOCK" > "$TREE/rootstock-install-patched"
    chmod +x "$TREE/rootstock-install-patched"
    adb shell mkdir -p /data/rootstock
    "$TREE/rootstock-install-patched" "$ROOTFS" "$SYSTEM"
    ;;

  *)
    sed -n "2,8p" "$0"
    exit 1
    ;;
esac

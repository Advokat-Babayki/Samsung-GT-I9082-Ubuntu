# Porting notes

## Status

Research. Nothing booted yet.

## Feasibility evidence (2026-11-20)

- UBports device list: no GT-I9082 / baffin entry. Forum answer: "there is no port for this device".
- `system-image.ubports.com` publishes no baffin channel.
- postmarketOS `samsung-baffin`: marked **not booting**, "What's working: Nothing", no mainline.
- Stock firmware boots and MTP works after partial heimdall flash (modem upload failed at ~100%).

## Candidate approaches

### 1. Legacy libhybris (Ubuntu Touch 15.04 "vivid", pre-Halium)

Base OS: CyanogenMod 12.1 (Android 5.1.1) device tree + kernel.
Pros: matches the newest reasonably complete device trees (pawitp, k2wl).
Cons: legacy build tooling is dead (phablet-tools, ubuntu-device-flash, old image server
channels); hybris glue (libhybris, android-headers) must match the 5.1 vendor blobs.

### 2. Halium 7.1 + UBports rootfs

Needs a working Android 7.1 base (device tree, kernel, vendor blobs) for baffin.
Pros: current UBports tooling and rootfs; lxc containers; installer support later.
Cons: no AOSP 7.1 device tree exists publicly; kernel is 3.x; vendor blobs are Android 5.1.
Halium 7.1 expects vendor blobs from a 7.1 system.

Decision: TODO after source audit.

## Sources found

| Component | Repo / branch | Notes |
|---|---|---|
| device tree | pawitp/android_device_samsung_i9082 `cm-12.0` | most complete, by CM maintainer |
| device tree | k2wl/android_device_samsung_baffin `master` | CM10.2, work in progress |
| kernel | pawitp/android_kernel_samsung_i9082 `cm-12.0` | 3.0.31 lineage |
| kernel | FraTeG/i9082_kernel `nougat` | 3.x with Nougat patches |
| kernel | codekidX/android_kernel_samsung_i9082 | "frost" |
| vendor | k2wl/android_vendor_samsung_i9082 | blobs extracted from stock |
| TWRP | https://dl.twrp.me/i9082/ | recovery |

## Hardware constraints

- No fastboot. Flashing only via Odin/Heimdall (download mode).
- Recovery partition can be overwritten with TWRP via heimdall `--RECOVERY`.
- No UART. Diagnostics via adb (if kernel boots far enough) or TWRP.
- 1 GB RAM: rootfs and container sizes must stay lean.
- Dual-SIM RIL (BCM28155) — expect radio issues on any port.

## Partition table

See `pit.txt` (dump from the device).

Key sizes (512-byte blocks): KERNEL 16384, RECOVERY 16384, system 3145728 (1.5 GiB),
HIDDEN 1146880 (560 MiB), userdata = rest, modem 38400.

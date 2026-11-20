# Ubuntu Touch for Samsung Galaxy Grand Duos (GT-I9082, "baffin")

Work-in-progress Ubuntu Touch (UBports) port.

**Status: research / bring-up.** No ready-made port exists for this device; UBports has no
official build and postmarketOS marks it as not booting. This repo is the port itself.

## Hardware

| | |
|---|---|
| SoC | Broadcom BCM28155 (Capri), dual-core Cortex-A9 @ 1.2 GHz |
| GPU | Broadcom VideoCore IV |
| RAM | 1 GB |
| Storage | 8 GB |
| Display | 480x800 TFT |
| Stock OS | Android 4.1.2, kernel 3.0.31 |
| Bootloader | Samsung Odin/Heimdall download mode (no fastboot) |

## Approach

TBD: Halium 7.1 port vs legacy libhybris (Ubuntu Touch 15.04). Decision and notes in
`docs/`. The device has unofficial CyanogenMod 12.0/12.1 trees and a Nougat kernel branch,
but no AOSP 7.x device tree yet.

## Sources

- Device tree (CM 12.0): https://github.com/pawitp/android_device_samsung_i9082
- Kernel (CM 12.0): https://github.com/pawitp/android_kernel_samsung_i9082
- Kernel (Nougat branch): https://github.com/FraTeG/i9082_kernel
- Vendor blobs: https://github.com/k2wl/android_vendor_samsung_i9082

## Repo layout

- `docs/` — porting notes, partition table, decisions
- `manifests/` — repo local manifests
- `scripts/` — build/flash helpers

## Flashing

Samsung download mode only (Volume Down + Home + Power, then Volume Up).
Use `heimdall` or Odin. Recovery: TWRP for i9082.

## License

Kernel code is GPLv2. Device tree follows the license of its upstream source.

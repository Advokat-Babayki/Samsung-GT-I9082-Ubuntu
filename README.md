# Ubuntu Touch for Samsung Galaxy Grand Duos (GT-I9082, "baffin")

Work-in-progress Ubuntu Touch (UBports) port.

**Status: bring-up.** Source tree syncing; nothing booted yet. There is no ready-made
port for this device; UBports has no official build and postmarketOS marks it as not
booting. This repo is the port itself.

Approach: legacy Ubuntu Touch 15.04 (vivid) on an Android 5.1.1 container
(`ubports/android` ubp-5.1 + i9082 device tree). Details in `docs/porting-notes.md`.

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

Legacy Ubuntu Touch 15.04 (vivid) on an Android 5.1.1 container. Base tree:
`ubports/android` branch `ubp-5.1`, device tree `osas514/android_device_samsung_i9082`
branch `aosp-5.1`. Halium 7.1 would need an AOSP 7.x device tree that does not exist.

## Sources

- Android tree: https://github.com/ubports/android (ubp-5.1)
- Device tree (AOSP 5.1): https://github.com/osas514/android_device_samsung_i9082
- Kernel (android-5.1): https://github.com/osas514/android_kernel_samsung_i9082
- Vendor blobs: https://github.com/speedbot/android_vendor_samsung_i9082
- Initramfs: https://github.com/ubports/ubports-boot
- Rootstock: https://github.com/ubports/rootstock-ng

## Repo layout

- `docs/` — porting notes, partition table, decisions
- `manifests/` — repo local manifests
- `scripts/` — build/flash helpers

## Flashing

Samsung download mode only (Volume Down + Home + Power, then Volume Up).
Use `heimdall` or Odin. Recovery: TWRP for i9082.

## License

Kernel code is GPLv2. Device tree follows the license of its upstream source.

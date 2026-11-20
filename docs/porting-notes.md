# Porting notes

## Status

Bring-up. Source tree syncing. Nothing booted yet.

## Chosen architecture: legacy Ubuntu Touch 15.04 (vivid)

Modern Ubuntu Touch (16.04+/Halium) needs an Android 7.1+ base and a Halium device
tree, neither of which exists for baffin. The legacy path matches the hardware and the
available sources:

| Part | Choice |
|---|---|
| Android base | `ubports/android` branch `ubp-5.1` (AOSP 5.1.1 + Ubuntu Touch additions) |
| Device tree | `osas514/android_device_samsung_i9082` branch `aosp-5.1` |
| Kernel | `osas514/android_kernel_samsung_i9082` branch `android-5.1` |
| Vendor blobs | `speedbot/android_vendor_samsung_i9082` |
| Ubuntu rootfs | vivid armhf rootfs from the UBports image server |
| Install method | `rootstock-touch-install` over TWRP adb |

Reference device tarballs were inspected to confirm the shape of a vivid port:
`ubuntu-touch/stable/w7` (LG L90) and `devel_stable/hammerhead` (Nexus 5, Android
5.1.1 LMY48W). Both ship:

- `partitions/boot.img` — kernel + Ubuntu initramfs (generic userland, no device .ko files)
- `partitions/recovery.img`
- `system/var/lib/lxc/android/system.img` — Android container (stripped, ~110-135 MB)
- `system/usr/local/bin/card_parameters_setter`, upstart jobs, udev rules

The Android container image also carries `/boot/android-ramdisk.img` (the Android
ramdisk, used by the Ubuntu initrd for fstab/hardware info) and `/ubuntu/*`
(prebuilt libhybris/audio/udev bits from the `ubuntu/*` projects in the manifest).

## Boot flow (vivid, "flipped" model)

1. boot.img kernel starts the Ubuntu initramfs (`scripts/touch`).
2. Initramfs finds the userdata partition (`datapart=` cmdline, else partition labels
   `userdata|UDA|DATAFS|USERDATA`), fsck's it and loop-mounts `/data/ubuntu.img`
   (ext2 image) as the rootfs.
3. `/var/lib/lxc/android/system.img` is loop-mounted at `/android/system`, Android
   ramdisk is extracted, Android fstab partitions mounted under `/android`.
4. Upstart starts the LXC Android container; libhybris from the rootfs talks to the
   Android HAL libs.

Install via `rootstock-touch-install <rootfs.tar.gz> <android-system.img>`: it wipes
`/data`, creates `/data/ubuntu.img`, unpacks the rootfs, drops the Android system
image into `/var/lib/lxc/android/`, links `/data/system.img` and reboots.

## Install notes

- The UBports image-server rootfs tarball (`ubuntu-*.tar.xz`) stores everything under
  a `system/` prefix; `rootstock-touch-install` expects the root at `./`. Repack with
  `tar xf ... --strip-components=1` (as root, to keep device nodes) and gzip it.
  `refs/vivid-preinstalled-touch-armhf.tar.gz` in the build tree is that repack.
- `rootstock-touch-install` refuses to run without `make_ext4fs`, but that tool is only
  used for sparse Android images. Ours is raw ext4, so `scripts/install.sh` strips the
  check.
- TWRP (3.0.2) must be flashed with heimdall first; it exposes adb as `recovery`, which
  rootstock requires.
- The Android system partition limits nothing here: the system image lands in
  `/data/ubuntu.img` (rootfs ext2 image) at `/var/lib/lxc/android/system.img`.
  A raw ext4 image is not shrunk by rootstock (the 120 MB repack only hits sparse images).

## Kernel requirements for LXC

`ubports-boot/check-kernel-config` list. The i9082 `cyanogenmod_i9082_defconfig`
(android-5.1 branch) is missing at least:

- `CONFIG_CPUSETS`
- `CONFIG_CGROUP_MEM_RES_CTLR`
- `CONFIG_SYSVIPC`
- `CONFIG_IPC_NS`
- `CONFIG_CGROUP_PERF`

These have to be enabled and the kernel rebuilt; without the cgroup/namespace
controllers the Android container will not start.

## Feasibility evidence (2026-11-20)

- UBports device list: no GT-I9082 / baffin entry. Forum answer: "there is no port for this device".
- `system-image.ubports.com` publishes no baffin channel.
- postmarketOS `samsung-baffin`: marked **not booting**, no mainline.
- Legacy vivid images are still downloadable from `system-image.ubports.com`
  (rootfs + device tarballs), so the vivid path has real material.
- Stock Android 4.1.2/4.2.2 boots after the heimdall flash (modem upload failed at the
  end, but the phone reaches MTP).

## Sources

| Component | Repo / branch | Notes |
|---|---|---|
| Android tree | ubports/android `ubp-5.1` | AOSP 5.1.1 + Ubuntu Touch additions |
| device tree | osas514/android_device_samsung_i9082 `aosp-5.1` | product `aosp_i9082` |
| kernel | osas514/android_kernel_samsung_i9082 `android-5.1` | 3.0.31 |
| vendor | speedbot/android_vendor_samsung_i9082 `master` | 40 MB of blobs |
| TWRP | https://dl.twrp.me/i9082/ | recovery for install/debug |
| rootstock | ubports/rootstock-ng | `rootstock-touch-install` |
| initramfs | ubports/ubports-boot | vivid initrd scripts |

## Hardware constraints

- No fastboot. Flashing only via Odin/Heimdall (download mode).
- No UART. Diagnostics via adb (if the kernel gets that far) or TWRP.
- 1 GB RAM: the Android container image and rootfs must stay lean.
- Dual-SIM RIL (BCM28155) — expect radio issues on any port.

## Partition table

See `pit.txt` (dump from the device).

Key sizes (512-byte blocks): KERNEL 16384, RECOVERY 16384, system 3145728 (1.5 GiB),
HIDDEN 1146880 (560 MiB), userdata = rest, modem 38400.

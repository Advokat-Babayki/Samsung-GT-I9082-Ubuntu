#!/usr/bin/env python3
"""Idempotent fixes applied to the ubports + i9082 tree before building.

Run inside the build tree (default /build). Every edit is guarded so the script
can be re-run on an already patched tree.
"""
import os
import re
import sys

TREE = os.environ.get("I9082_TREE", "/build")
os.chdir(TREE)


def edit(path, old, new, count=1):
    try:
        with open(path) as f:
            text = f.read()
    except FileNotFoundError:
        print("skip missing", path)
        return
    if new in text:
        return
    if old not in text:
        print("pattern not found in", path)
        return
    with open(path, "w") as f:
        f.write(text.replace(old, new, count))


def drop_lines(path, needles):
    try:
        with open(path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        print("skip missing", path)
        return
    out = [l for l in lines if not any(n in l for n in needles)]
    with open(path, "w") as f:
        f.writelines(out)


def append_once(path, line):
    try:
        with open(path) as f:
            text = f.read()
    except FileNotFoundError:
        print("skip missing", path)
        return
    if line.rstrip("\n") in text:
        return
    with open(path, "a") as f:
        f.write(("\n" if not text.endswith("\n") else "") + line + "\n")


# --- kernel -----------------------------------------------------------------
defconf = "kernel/samsung/i9082/arch/arm/configs/cyanogenmod_i9082_defconfig"
for opt in ("CONFIG_CPUSETS", "CONFIG_CGROUP_MEM_RES_CTLR", "CONFIG_SYSVIPC",
            "CONFIG_IPC_NS", "CONFIG_CGROUP_PERF"):
    append_once(defconf, f"{opt}=y")
edit(defconf, "CONFIG_KERNEL_GZIP=y", "# CONFIG_KERNEL_GZIP is not set")
edit(defconf, "# CONFIG_KERNEL_LZMA is not set", "CONFIG_KERNEL_LZMA=y")

# committed merge-conflict markers
with open("kernel/samsung/i9082/drivers/gpio/pca953x.c") as f:
    text = f.read()
text = re.sub(r"^<<<<<<< HEAD\n(.*?)^=======\n(.*?)^>>>>>>> android-3.0\n",
              lambda m: m.group(1), text, flags=re.S | re.M)
with open("kernel/samsung/i9082/drivers/gpio/pca953x.c", "w") as f:
    f.write(text)

# --- device tree ------------------------------------------------------------
board = "device/samsung/i9082/BoardConfig.mk"
edit(board, "BOARD_KERNEL_CMDLINE := console=ttyS0,115200n8 mem=832M@0xA2000000 "
            "androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000",
     "BOARD_KERNEL_CMDLINE := console=ttyS0,115200n8 mem=832M@0xA2000000 "
     "androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000 "
     "datapart=/dev/block/mmcblk0p21")
append_once(board, "TARGET_KERNEL_SOURCE := kernel/samsung/i9082")
append_once(board, "BOARD_USE_LOCAL_INITRD := true")

edit("device/samsung/i9082/aosp_i9082.mk",
     "PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml",
     "# removed: device/sample is not part of the ubports manifest")
edit("device/samsung/i9082/aosp_i9082.mk",
     """PRODUCT_PACKAGES += \\
    Galaxy4 \\
    HoloSpiralWallpaper \\
    LiveWallpapers \\
    LiveWallpapersPicker \\
    MagicSmokeWallpapers \\
    NoiseField \\
    PhaseBeam \\
    VisualizationWallpapers \\
    PhotoTable \\
    Mms \\
    Stk \\
    CellBroadcastReceiver \\
    SoundRecorder \\
\tLauncher3""",
     "# Android apps are not used by Ubuntu Touch; keep the container minimal and avoid\n"
     "# dependencies on packages/wallpapers and friends that are not in the ubports manifest")

drop_lines("device/samsung/i9082/device_i9082.mk", ["LivePicker"])
drop_lines("vendor/samsung/i9082/i9082-vendor.mk", ["packages/wallpapers/LivePicker"])

# --- build system -----------------------------------------------------------
edit("system/core/mkbootimg/Android.mk",
     "LOCAL_CFLAGS := -Werror -Wno-error=stringop-truncation",
     "LOCAL_CFLAGS := -Werror")
edit("system/core/libutils/Android.mk",
     " -Wno-error=class-memaccess -Wno-error=implicit-fallthrough"
     " -Wno-error=ignored-qualifiers -Wno-error=cast-function-type",
     " -Wno-error=ignored-qualifiers")
edit("system/core/fastboot/Android.mk", " -Wno-error=format-truncation", "")

# __android_log_error_write does not exist in the 5.1 liblog
edit("system/core/include/log/log.h",
     "#define android_errorWriteLog(tag, subTag) \\\n"
     "    __android_log_error_write(tag, subTag, -1, NULL, 0)",
     "#define android_errorWriteLog(tag, subTag) ((void)0)")
edit("system/core/include/log/log.h",
     "#define android_errorWriteWithInfoLog(tag, subTag, uid, data, dataLen) \\\n"
     "    __android_log_error_write(tag, subTag, uid, data, dataLen)",
     "#define android_errorWriteWithInfoLog(tag, subTag, uid, data, dataLen) ((void)0)")
edit("system/media/camera/src/camera_metadata.c",
     'android_errorWriteLog(SN_EVENT_LOG_ID, "30741779");',
     'ALOGE("camera_metadata: count overflow");')
edit("system/media/camera/src/camera_metadata.c",
     'android_errorWriteLog(SN_EVENT_LOG_ID, "30591838");',
     'ALOGE("camera_metadata: data_count > capacity");')

# ubports' subdir list omits audio policy and soundtrigger
edit("build/core/main.mk",
     "\tframeworks/av/services/audioflinger \\\n",
     "\tframeworks/av/services/audioflinger \\\n"
     "\tframeworks/av/services/audiopolicy \\\n"
     "\tframeworks/av/services/soundtrigger \\\n"
     "\tframeworks/av/soundtrigger \\\n")

print("tree fixes applied")

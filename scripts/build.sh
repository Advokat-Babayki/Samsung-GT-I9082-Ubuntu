#!/usr/bin/env bash
# Build environment and build steps for the GT-I9082 Ubuntu Touch port.
# Host: any Linux with docker and python3. Android build runs in Ubuntu 16.04.
#
# Usage:
#   scripts/build.sh env     # create/refresh the build container
#   scripts/build.sh sync    # repo init + repo sync on the host (first run ~15 GB)
#   scripts/build.sh build   # build boot.img + system.img
#
# Tree lives outside the repo (default ~/i9082-ut) so it is never committed.
set -euo pipefail

TREE="${I9082_TREE:-$HOME/i9082-ut}"
CONTAINER="${I9082_CONTAINER:-i9082-build}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
JDK="$TREE/tools/zulu7.56.0.11-ca-jdk7.0.352-linux_x64"

docker_exec() { docker exec "$CONTAINER" bash -lc "$*"; }

case "${1:-}" in
  env)
    docker pull ubuntu:16.04
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    mkdir -p "$TREE/tools"
    # --network=host: the default bridge has no outbound connectivity on this host
    docker run -d --network=host --name "$CONTAINER" \
      -v "$TREE:/build" -v "$REPO_DIR:/port:ro" -w /build ubuntu:16.04 sleep infinity
    docker_exec '
      set -e
      export DEBIAN_FRONTEND=noninteractive
      echo "Acquire::ForceIPv4 \"true\";" > /etc/apt/apt.conf.d/99force-ipv4
      apt-get update
      apt-get install -y git gnupg flex bison gperf build-essential zip curl \
        zlib1g-dev libc6-dev libncurses5-dev lib32z1-dev lib32ncurses5-dev \
        x11proto-core-dev libx11-dev libgl1-mesa-dev g++-multilib tofrodos \
        python-markdown libxml2-utils xsltproc openjdk-8-jdk pngcrush schedtool \
        bc ccache rsync lzop libssl-dev file vim-common less unzip gcc-4.8 g++-4.8
      update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-4.8
      git config --global user.name "port builder"
      git config --global user.email "build@localhost"'
    ;;

  sync)
    cd "$TREE"
    if [ ! -d .repo ]; then
      curl -fsSL -o repo https://raw.githubusercontent.com/aosp-mirror/tools_repo/master/repo
      chmod +x repo
      python3 repo init -u https://github.com/ubports/android -b ubp-5.1 --no-repo-verify
    fi
    mkdir -p .repo/local_manifests
    cp "$REPO_DIR/manifests/i9082.xml" .repo/local_manifests/
    python3 repo sync -c -j4
    ;;

  build)
    docker_exec '
      set -e
      export JAVA_HOME='"$JDK"'
      export PATH="$JAVA_HOME/bin:$PATH"
      cd /build
      # LXC needs these controllers; the device defconfig does not have them
      DEFCONF=kernel/samsung/i9082/arch/arm/configs/cyanogenmod_i9082_defconfig
      for opt in CONFIG_CPUSETS CONFIG_CGROUP_MEM_RES_CTLR CONFIG_SYSVIPC \
                 CONFIG_IPC_NS CONFIG_CGROUP_PERF; do
        grep -q "^$opt=y" "$DEFCONF" || echo "$opt=y" >> "$DEFCONF"
      done
      source build/envsetup.sh
      lunch aosp_i9082-userdebug
      mka ubports-boot
      mka systemimage 2>&1 | tee build.log'
    ;;

  *)
    sed -n "2,9p" "$0"
    exit 1
    ;;
esac

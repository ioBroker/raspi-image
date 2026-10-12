#!/bin/bash
# Builds a Raspberry Pi 5 image with preinstalled ioBroker WITHOUT Raspberry hardware.
# Runs on: GitHub Actions (ubuntu-24.04-arm), any Linux, WSL2 on Windows.
# On x86 hosts ARM64 emulation is needed: sudo apt install qemu-user-static
#
# Usage: sudo ./build.sh
# Env:   IMG_URL       source image (default: newest Raspberry Pi OS Lite 64-bit)
#        EXTRA_MB      extra space in the root partition for the build (default 3072)
#        IOB_PASSWORD  password of user "iob" (default 2024=smart!)
#        HOSTNAME_IMG  hostname (default iobroker)
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-$HERE/work}
OUT=${OUT:-$HERE/out}
IMG_URL=${IMG_URL:-https://downloads.raspberrypi.com/raspios_lite_arm64_latest}
EXTRA_MB=${EXTRA_MB:-3072}
IOB_PASSWORD=${IOB_PASSWORD:-2024=smart!}
HOSTNAME_IMG=${HOSTNAME_IMG:-iobroker}

[ "$(id -u)" = 0 ] || { echo "Please run as root (sudo)"; exit 1; }

if [ "$(uname -m)" != "aarch64" ] && [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  echo "ARM64 emulation missing. Install it: sudo apt install qemu-user-static binfmt-support"
  exit 1
fi

mkdir -p "$WORK" "$OUT"
MNT="$WORK/mnt"
ROOT_LOOP=""; BOOT_LOOP=""

cleanup() {
  set +e
  for d in boot/firmware dev/pts dev proc sys; do
    mountpoint -q "$MNT/$d" && umount -l "$MNT/$d"
  done
  mountpoint -q "$MNT" && umount -l "$MNT"
  [ -n "$BOOT_LOOP" ] && losetup -d "$BOOT_LOOP"
  [ -n "$ROOT_LOOP" ] && losetup -d "$ROOT_LOOP"
}
trap cleanup EXIT

# ---------- 1. Download newest image ----------
REAL_URL=$(curl -fsSIL -o /dev/null -w '%{url_effective}' "$IMG_URL")
SRC_NAME=$(basename "$REAL_URL" .img.xz)          # e.g. 2026-10-06-raspios-trixie-arm64-lite
echo ">>> Source: $REAL_URL"
curl -fL --retry 3 -o "$WORK/src.img.xz" "$REAL_URL"
curl -fsSL "$REAL_URL.sha256" | awk '{print $1"  '"$WORK"'/src.img.xz"}' | sha256sum -c -

IMG="$WORK/build.img"
xz -dc -T0 "$WORK/src.img.xz" > "$IMG"
rm -f "$WORK/src.img.xz"

# ---------- 2. Enlarge root partition ----------
truncate -s +"${EXTRA_MB}"M "$IMG"
parted -s "$IMG" resizepart 2 100%

part() { parted -m -s "$IMG" unit B print | awk -F: -v n="$1" '$1==n {gsub("B","",$2); gsub("B","",$4); print $2, $4}'; }
read -r BOOT_OFF BOOT_SIZE < <(part 1)
read -r ROOT_OFF ROOT_SIZE < <(part 2)

ROOT_LOOP=$(losetup -f --show -o "$ROOT_OFF" --sizelimit "$ROOT_SIZE" "$IMG")
BOOT_LOOP=$(losetup -f --show -o "$BOOT_OFF" --sizelimit "$BOOT_SIZE" "$IMG")
e2fsck -fy "$ROOT_LOOP" || true
resize2fs "$ROOT_LOOP"

# ---------- 3. Mount ----------
mkdir -p "$MNT"
mount "$ROOT_LOOP" "$MNT"
mount -t vfat "$BOOT_LOOP" "$MNT/boot/firmware"   # needed so kernel updates land in bootfs
mount --bind /dev "$MNT/dev"
mount --bind /dev/pts "$MNT/dev/pts"
mount -t proc proc "$MNT/proc"
mount -t sysfs sys "$MNT/sys"

cp "$MNT/etc/resolv.conf" "$WORK/resolv.conf.orig"
cp -L /etc/resolv.conf "$MNT/etc/resolv.conf"

# ---------- 4. Install ioBroker in chroot ----------
cp "$HERE/customize.sh" "$MNT/tmp/customize.sh"
# Own UTS namespace: ioBroker stores the hostname in its objects (system.host.<name>).
# Without this the build host name (e.g. "runnervm...") would end up in the image.
unshare --uts /bin/sh -c "hostname '$HOSTNAME_IMG' && exec chroot '$MNT' /usr/bin/env -i \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/root TERM=dumb HOSTNAME_IMG='$HOSTNAME_IMG' \
  /bin/bash /tmp/customize.sh"
rm -f "$MNT/tmp/customize.sh"
cp "$WORK/resolv.conf.orig" "$MNT/etc/resolv.conf"

NODE_VER=$(chroot "$MNT" node -v 2>/dev/null || echo "?")
CTRL_VER=$(chroot "$MNT" node -p "require('/opt/iobroker/node_modules/iobroker.js-controller/package.json').version" 2>/dev/null || echo "?")

# ---------- 5. First boot: user, hostname, SSH via cloud-init ----------
HASH=$(openssl passwd -6 "$IOB_PASSWORD")
sed -e "s|@HOSTNAME@|$HOSTNAME_IMG|" -e "s|@PASSWD_HASH@|$HASH|" \
  "$HERE/user-data.template" > "$MNT/boot/firmware/user-data"

# ---------- 6. Finish ----------
fstrim -v "$MNT" || true      # free blocks become holes => image compresses well
cleanup
trap - EXIT

OUT_NAME="ioBroker-image-RPi_5_$(date +%Y_%m_%d)"
mv "$IMG" "$OUT/$OUT_NAME.img"
echo ">>> Compressing..."
xz -T0 -6 -f "$OUT/$OUT_NAME.img"
( cd "$OUT" && sha256sum "$OUT_NAME.img.xz" > "$OUT_NAME.img.xz.sha256" )
cat > "$OUT/release-notes.md" <<EOF
ioBroker image for Raspberry Pi 5

- Base: \`$SRC_NAME\`
- Node.js: \`$NODE_VER\`
- js-controller: \`$CTRL_VER\`
- Login: \`iob\` / \`$IOB_PASSWORD\` (change after first login with \`passwd\`)
- Admin: http://$HOSTNAME_IMG.local:8081
EOF
echo ">>> Done: $OUT/$OUT_NAME.img.xz (based on $SRC_NAME)"

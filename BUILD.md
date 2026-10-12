# Build the image without Raspberry Pi hardware

The image is built from the newest **Raspberry Pi OS Lite (64-bit)** in a chroot.
No Raspberry Pi, no SD card, no manual copying with HDDRawCopy.

## GitHub Actions (recommended)

1. Open **Actions** > **Build Raspberry Pi 5 image** > **Run workflow**.
2. Optional: tick **Publish as GitHub Release**.
3. After about 20 to 40 minutes the image is available as workflow artifact
   (and as release asset if publishing was selected).

The job runs on the native ARM64 runner `ubuntu-24.04-arm`, so no emulation is needed.

## Local: Linux or Windows (WSL2)

```bash
# Windows: wsl --install -d Ubuntu, then inside Ubuntu:
sudo apt install -y qemu-user-static binfmt-support xz-utils parted e2fsprogs dosfstools openssl git
git clone https://github.com/ioBroker/raspi-image && cd raspi-image
sudo ./build.sh
```

Work inside the Linux file system (`~/`), not under `/mnt/c`.
On x86 the build runs under emulation and takes noticeably longer (about 1 to 2 hours).

Result: `out/ioBroker-image-RPi_5_YYYY_MM_DD.img.xz`

## What happens

| Step | File |
|------|------|
| Download newest Raspberry Pi OS Lite, verify SHA256, enlarge root partition | `build.sh` |
| `apt upgrade`, SSH, timezone, ioBroker installer, `welcome` + `wireless-settings`, `iob unsetup` | `customize.sh` |
| Remove SSH host keys, machine-id, Wi-Fi connections, apt caches | `customize.sh` |
| User `iob`, hostname `iobroker`, SSH password login on first boot | `user-data.template` (cloud-init) |

On first boot the Pi creates new SSH host keys, a new machine-id and expands the
file system to the whole card. ioBroker generates a new UUID on its first start.

## Options

| Variable | Default |
|----------|---------|
| `IMG_URL` | newest Raspberry Pi OS Lite arm64 |
| `IOB_PASSWORD` | `2024=smart!` |
| `HOSTNAME_IMG` | `iobroker` |
| `EXTRA_MB` | `3072` |

If the image is written with Raspberry Pi Imager and "OS customisation" is used,
Imager replaces `user-data` and its own user/hostname/Wi-Fi settings apply.

# Build the image without Raspberry Pi hardware

The image is built from the newest **Raspberry Pi OS Lite (64-bit)** in a chroot.
No Raspberry Pi, no SD card, no manual copying with HDDRawCopy.

## GitHub Actions (recommended)

1. Open **Actions** > **Build Raspberry Pi 5 image** > **Run workflow**.
2. Optional: tick **Publish as GitHub Release**.
3. After about 20 to 40 minutes the image is available as workflow artifact
   (and as release asset if publishing was selected).

With the option **Upload to iobroker.live** (default on) the workflow additionally:

1. uploads `ioBroker-image-RPi_5_YYYY_MM_DD.zip` and its `.sha256` via SFTP to
   `https://iobroker.live/images/ioBroker-image-RPi_5_YYYY_MM_DD.zip`
   (folder `/images` for the main account, `/` for an account restricted to `/images`),
   and checks that the URL delivers the complete file
2. opens a pull request in [ioBroker.docs](https://github.com/ioBroker/ioBroker.docs) that
   changes the download link in `engine-2/front-end/src/config/installation.json`.
   Older open PRs of this kind are closed as superseded.

Test the image, then merge the docs PR. Until then the website keeps the old link.

Each step only runs if its secrets are set (repository or organization secrets):

| Secret | Used for |
|--------|----------|
| `VAR_ACTIONS_SFPT_HOST` | SFTP host (same names as in ioBroker.repobuilder) |
| `VAR_ACTIONS_SFPT_PORT` | SFTP port, optional (22) |
| `VAR_ACTIONS_SFTP_USERNAME` | SFTP user |
| `VAR_ACTIONS_SFTP_PASSWORD` | SFTP password |
| `DOCS_PR_TOKEN` | Token with write access to ioBroker.docs (fine-grained: Contents + Pull requests read/write) |

The job runs on the native ARM64 runner `ubuntu-24.04-arm`, so no emulation is needed.

## Local: Linux or Windows (WSL2)

```bash
# Windows: wsl --install -d Ubuntu, then inside Ubuntu:
sudo apt install -y qemu-user-static binfmt-support xz-utils parted e2fsprogs dosfstools openssl zip git
git clone https://github.com/ioBroker/raspi-image && cd raspi-image
sudo ./build.sh
```

Work inside the Linux file system (`~/`), not under `/mnt/c`.
On x86 the build runs under emulation and takes noticeably longer (about 1 to 2 hours).

Result: `out/ioBroker-image-RPi_5_YYYY_MM_DD.zip`

## What happens

| Step | File |
|------|------|
| Download newest Raspberry Pi OS Lite, verify SHA256, enlarge root partition | `build.sh` |
| `apt upgrade`, SSH, timezone, ioBroker installer, `welcome` + `wireless-settings`, `iob unsetup` | `customize.sh` |
| Remove SSH host keys, machine-id, Wi-Fi connections, apt caches | `customize.sh` |
| Upload to iobroker.live, PR in ioBroker.docs | `upload-sftp.sh`, `docs-pr.sh` |
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

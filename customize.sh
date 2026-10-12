#!/bin/bash
# Runs INSIDE the chroot of the Raspberry Pi OS Lite image.
# Chroot variant of install.sh: no running systemd, no shutdown, no reboot.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8 LC_ALL=C.UTF-8

# The ioBroker installer recognises systemd via "ps -p 1 -o comm=".
# In a chroot PID 1 belongs to the build host, so we answer "systemd" here.
# systemctl itself detects the chroot: "enable" works, "start/stop" are ignored.
SHIM=/tmp/iob-shim
mkdir -p "$SHIM"
cat > "$SHIM/ps" <<'EOF'
#!/bin/sh
if [ "$*" = "-p 1 -o comm=" ]; then echo systemd; exit 0; fi
exec /usr/bin/ps "$@"
EOF
chmod +x "$SHIM/ps"
export PATH="$SHIM:$PATH"

# Hostname (build runs in its own UTS namespace with this name)
HOSTNAME_IMG=${HOSTNAME_IMG:-iobroker}
echo "$HOSTNAME_IMG" > /etc/hostname
sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME_IMG/" /etc/hosts

# NTP
sed -i 's/^#NTP=.*/NTP=time.google.com/' /etc/systemd/timesyncd.conf

# Optional: keep kernel/firmware unchanged (only for builds without a mounted bootfs)
if [ "${HOLD_KERNEL:-0}" = "1" ]; then
  apt-mark hold linux-image-rpi-2712 linux-image-rpi-v8 raspi-firmware >/dev/null 2>&1 || true
fi

apt-get update
apt-get -y -o Dpkg::Options::=--force-confold upgrade

# SSH on, root login off
systemctl enable ssh
sed -i 's/^#\?\s*PermitRootLogin\s.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Root password (as in the original install.sh)
echo "root:${ROOT_PASSWORD:-2024=smartroot!}" | chpasswd

# Timezone (timedatectl does not work without systemd)
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# ioBroker
apt-get -y install net-tools curl wget openssh-server build-essential ca-certificates nano git
curl -sLf https://iobroker.net/install.sh | bash -s -- --no-autostart

# ioBroker is not running (--no-autostart). The CLI works directly on the
# jsonl databases. Run it as user "iobroker" so file ownership stays correct.
iobcli() {
  (cd /opt/iobroker && runuser -u iobroker -- env HOME=/home/iobroker \
    node /opt/iobroker/node_modules/iobroker.js-controller/iobroker.js "$@")
}
iobcli add welcome
iobcli add wireless-settings
# Reset UUID: on first start the system gets a new one
iobcli unsetup -y

# ---------- Cleanup: nothing device specific may stay in the image ----------
apt-get -y autoremove --purge
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /etc/NetworkManager/system-connections/*
rm -f /etc/ssh/ssh_host_*            # regenerated on first boot
echo "uninitialized" > /etc/machine-id  # systemd first boot
rm -f /var/lib/dbus/machine-id
cloud-init clean --logs --seed 2>/dev/null || true
rm -rf /root/.npm /root/.cache /home/*/.npm /home/iobroker/.npm 2>/dev/null || true
rm -f /root/.bash_history
rm -rf "$SHIM"
echo "customize.sh finished"

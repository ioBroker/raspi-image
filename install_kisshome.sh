#!/bin/bash -e
# Add time.google.com to NTP service
sudo sed -i 's/^#NTP=.*/NTP=time.google.com/' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd

sudo apt-get update
sudo apt-get upgrade -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Check if user 'iob' exists, if not create it
if id "iob" &>/dev/null; then
  echo "User 'iob' already exists."
else
  echo "Creating user 'iob'."
  sudo useradd -m -G sudo iob
  echo "iob:2024=smart!" | sudo chpasswd
fi

# Set root password
echo "root:2024=smartroot!" | sudo chpasswd
sudo sed -i 's/^#\?\s*PermitRootLogin\s.*/PermitRootLogin no/' "/etc/ssh/sshd_config"
sudo systemctl restart sshd

# Setup timezone
sudo timedatectl set-timezone Europe/Berlin
sudo dpkg-reconfigure --frontend noninteractive tzdata

# Install iobroker
sudo apt-get -y install net-tools curl wget openssh-server build-essential ca-certificates nano
curl -sLf https://iobroker.net/install.sh | bash -
cd /opt/iobroker
iob stop

# Settings for kisshome
iob add kisshome-defender
iob add welcome
iob add wireless-settings
# End of settings for kisshome
iob unsetup -y

# Clean up
sudo rm -rf /opt/raspi-image/
sudo rm -rf /etc/NetworkManager/system-connections/*
history -c
sudo shutdown -h now
# now you can stop the raspberrypi and create an image

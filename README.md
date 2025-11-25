# raspi-image
Creates Raspberry Pi Image with preinstalled admin, welcome and wireless-settings adapters

## How to start
Create first with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) the Raspberry Pi 5 image.

![step1](step1.png)

![step2](step2.png)

![step3](step3.png)

### ioBroker image
Use hostname `iobroker`, login `iob` and password `2024=smart!` by creation of the image.

```bash
sudo sed -i 's/^#NTP=.*/NTP=time.google.com/' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd
echo sudo apt update
sudo apt install -y git
cd /opt
sudo git clone https://github.com/GermanBluefox/kisshome-raspi-image
sudo chmod +x /opt/kisshome-raspi-image/install.sh
sudo /opt/kisshome-raspi-image/install.sh
```

### Kisshome image
Use hostname `kisshome`, login `iob` and password `2024=smart!` by creation of the image.

```bash
sudo sed -i 's/^#NTP=.*/NTP=time.google.com/' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd
echo sudo apt update
sudo apt install -y git
cd /opt
sudo git clone https://github.com/GermanBluefox/kisshome-raspi-image
sudo chmod +x /opt/kisshome-raspi-image/install_kisshome.sh
sudo /opt/kisshome-raspi-image/install_kisshome.sh
```

## Copy image
Use [HDDRawCopy1.20Portable.exe](https://hddguru.com/software/HDD-Raw-Copy-Tool/HDDRawCopy1.20Portable.exe) or [win32diskimager-1.0.0-install.exe](https://sourceforge.net/projects/win32diskimager/files/latest/download) to make an image.

![step4](step4.png)

## After creation
The ssh login is `iob` and the password is `2024=smart!`. Change the password immediately after the first reboot!

The root password is `2024=smartroot!`.

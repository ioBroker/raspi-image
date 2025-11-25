### Kisshome image
Use hostname `kisshome`, login `iob` and password `2024=smart!` by creation of the image.

```bash
sudo sed -i 's/^#NTP=.*/NTP=time.google.com/' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd
echo sudo apt update
sudo apt install -y git
cd /opt
sudo git clone https://github.com/ioBroker/raspi-image
sudo chmod +x /opt/kisshome-raspi-image/install_kisshome.sh
sudo /opt/kisshome-raspi-image/install_kisshome.sh
```
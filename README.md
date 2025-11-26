For english version, see [english](#english-instructions)

# Deutsch
## Schreibe image to SD card — Windows, Linux, macOS

> Wichtig: Immer das korrekte Zielgerät prüfen. Ein falsches Ziel löscht Daten.

### Prerequisites
- Raspberry Pi 5  
- SD-Karte (empfohlen: mindestens 16 GB)
- Karenleser für den PC
- Download image von https://www.iobroker.net/#de/download

### Windows (GUI, empfohlen)
1. Installiere und starte [`balenaEtcher`](https://etcher.balena.io/).
2. Wähle das Image (`path/to/ioBroker-image-RPi_5_20XX_XX_XX.zip`).
3. Wähle die SD‑Karte als Ziel.
4. Starte den Schreibvorgang und warte, bis er abgeschlossen ist.
5. Karte sicher auswerfen.

### Linux (GUI oder CLI)
#### GUI
- Nutze [`balenaEtcher`](https://etcher.balena.io/) wie unter Windows.

#### CLI (sicher und schnell)
1. Gerät identifizieren:  
   `lsblk`
2. Image entpacken (ersetze `path/to/*`):
   `unzip path/to/ioBroker-image-RPi_5_20XX_XX_XX.zip -d .`
3. Alle Partitionen des Ziels unmounten (ersetze `/dev/sdX`):  
   `sudo umount /dev/sdX*`
4. Image schreiben (ersetze Pfad und Gerät):  
   `sudo dd if=iobroker-image.img of=/dev/sdX bs=4M status=progress conv=fsync`
5. Schreibcache leeren und fertigstellen:  
   `sudo sync`
6. Karte sicher entfernen.

### macOS (GUI oder CLI)
#### GUI
- Nutze [`balenaEtcher`](https://etcher.balena.io/).

#### CLI
1. Liste der Laufwerke anzeigen:  
   `diskutil list`
2. Image entpacken (ersetze `path/to/*`):
   `unzip path/to/ioBroker-image-RPi_5_20XX_XX_XX.zip -d .`
3. Ganze Karte unmounten (ersetze `diskN`):  
   `sudo diskutil unmountDisk /dev/diskN`
4. Image schreiben (nutze `rdisk` für bessere Geschwindigkeit):  
   `sudo dd if=iobroker-image.img of=/dev/rdiskN bs=4m status=progress`
5. Karte auswerfen:  
   `sudo diskutil eject /dev/diskN`

### Hinweise & Troubleshooting
- Achte genau auf das Zielgerät (`/dev/sdX`, `diskN`). Ein Fehler löscht Daten.
- `status=progress` zeigt Fortschritt bei `dd` (Linux/macOS).
- Bei Problemen: Karte nochmal partitionieren/formattieren, andere SD‑Karte oder Adapter testen.
- Nach dem Erstellen des Images ggf. die erste Boot‑Konfiguration (SSH, WLAN, Hostname) anpassen.

### Verbindung zum Raspberry Pi
Nach dem als die SD-Karte ins Raspberry Pi eingesetzt und gestartet wurde, kann über SSH eine Verbindung hergestellt werden:

```bash
ssh iob@kisshome
```

Password: `2024=smart!` (Bitte unbedingt nach dem Login mit `passwd` ändern)

Man sollte auch im Browser unter http://iobroker.local:8081 die ioBroker Admin-Oberfläche erreichen können.

# English instructions
## Write image to SD card — Windows, Linux, macOS

> Important: Always verify the target device. Writing to the wrong device will erase data.

### Prerequisites
- Raspberry Pi 5
- SD-Card (suggested: minimal 16 GB)
- Card-reader for PC
- Download image from https://www.iobroker.net/#en/download

### Windows (GUI, recommended)
1. Install and start `balenaEtcher` (`https://etcher.balena.io/`).
2. Select the image (for example `path/to/iobroker-image-RPi_5_20XX_XX_XX.zip`).
3. Select the SD card as the target.
4. Start the write process and wait until it finishes.
5. Safely eject the card.

### Linux (GUI or CLI)
#### GUI
- Use `balenaEtcher` as on Windows.

#### CLI (safe and fast)
1. Identify drives:
   `lsblk`
2. Unpack the image (replace `path/to/*`):
   `unzip path/to/iobroker-image-RPi_5_20XX_XX_XX.zip -d .`
3. Unmount all partitions of the target (replace `/dev/sdX`):
   `sudo umount /dev/sdX*`
4. Write the image (replace paths and device):
   `sudo dd if=iobroker-image.img of=/dev/sdX bs=4M status=progress conv=fsync`
5. Flush write cache:
   `sudo sync`
6. Remove the card safely.

### macOS (GUI or CLI)
#### GUI
- Use `balenaEtcher`.

#### CLI
1. List disks:
   `diskutil list`
2. Unpack the image (replace `path/to/*`):
   `unzip path/to/iobroker-image-RPi_5_20XX_XX_XX.zip -d .`
3. Unmount the entire card (replace `diskN`):
   `sudo diskutil unmountDisk /dev/diskN`
4. Write the image (use `rdisk` for faster access):
   `sudo dd if=iobroker-image.img of=/dev/rdiskN bs=4m status=progress`
5. Eject the card:
   `sudo diskutil eject /dev/diskN`

### Notes & Troubleshooting
- Double-check the target device (`/dev/sdX`, `diskN`). A wrong device will delete data.
- Use `status=progress` to see progress with `dd`.
- If problems occur: repartition/format the card, try another SD card or adapter.
- After creating the image, adjust first-boot settings (SSH, Wi\-Fi, hostname) as needed.

### Connecting to the Raspberry Pi
After inserting the SD card and booting the Pi, connect via SSH:

`ssh iob@kisshome`

Password: `2024=smart!` (Please change it immediately after login with `passwd`)

The ioBroker admin UI should be available at:

http://iobroker.local:8081

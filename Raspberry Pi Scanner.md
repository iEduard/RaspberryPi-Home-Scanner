# Fujitsu ScanSnap iX500 und der Raspberry Pi

Oh mann was habe ich alles durchgemacht um das Projekt fertig zu bekommen... Ich habe das ganze mit den folgenden komponenten realisiert:

- Raspberry Pi 4B 4Gb Ram  🤷‍♂️
- Raspberry Pi USB-C Netzteil
- Fujitsu ScanSnap iX500 

## Langsam aufwärmen
Rasbian Lite installieren und aktualisieren. Ich habe für mein Projekt das Rasbian Buster light Image genutzt da ich mit dem RaspberryPi 4 keine ältere Version nutzen konnte und die Leight Version weil ich keinen Desktop brauche.

Installation des Rasbian mache ich immer über den Apple Pi Baker. Anschließend noc eine ssh Datei auf den Speicher selber packen oder über den Apple pi Baker direkt machen lassen. Geht beides 😊
Anschließend den Speicher in den Pi via ssh verbinden und das System aktualisieren mit den beiden Befehlen.

>$ sudo apt-get update
>
>$ sudo apt-get upgrade

## Sane

sane ist die treiber schnittstelle zu unserem scanner. Sane besitzt treiber und funktionalität für viele scanner. Wir installieren alles. müsst man nicht wenn man seinen scanner bereits kennt. Wir machen dennoch das komplette Paket da es mir egal sein soll welchen scanner ich anschließend anhänge.

### Sane installieren
>$ sudo apt install sane -y

wegen dem rasbian Buster release muss noch eine Datei mit ein Eintrag hinzugefügt werden. Dies ist notwendig für mich da die Nutzer die sich über ssh 
Zu erst die neue Datei erstellen.

>$ sudo nano /etc/udev/rules.d/70-libsane-group.rules

Anschließend diesen eintrag in die neue Datei kopieren und speichern.

> ENV{libsane_matched}=="yes", RUN+="/bin/setfacl -m g:scanner:rw $env{DEVNAME}"

Siehe diesen Artikel für mehr informationen. (https://www.raspberrypi.org/forums/viewtopic.php?t=243513)

### Set the user to the Autorized group
>$ sudo usermod -a -G scanner pi

Muss ich eventuell den user auch zur gruppe saned hinzufügen?

### Auslesen der Scanner Grupe wer hier die rechte hat
>$ getent group scanner

### Reboot tut gut
Jup jup jup... das ist leider notwendig. Ihr müsst den pi tatsächlich neustarten damit ihr den Scanner auch ohne sudo findet.

### Scanner suchen
>$ sane-find-scanner -q
>
>$ scanimage --list-devices

### Test Scan
Mit Resbian Stretch ist das hier ohne sudo ausführbar. Mit dem resbian Buster muss sudo verwendet werden da sonst der Scanner nicht gefunden wird...

>$ sudo scanimage >/tmp/out.pnm

## scanbd

scanbd ist ein deamon dergenutzt wird um den Tastendruck auf dem Scanner zu identifizieren und anschließend ein script auszuführen. Die Dokumentation von scanbd ist leider nicht sonderlich gut. Aber in diesem post aud superuser.com bekommt man einen guten einblick. https://superuser.com/questions/1043092/sane-scanning-scanbd-buttons-and-service-permissions/1044684#1044684


### Installation
zu erst müssen wir scanbd installieren. Das machen wir mit dem folgenden kommando.

>$ sudo apt install scanbd -y

Anschließend dann die Konfiguration anpassen. Die Datei "/etc/scanbd/scanbd.conf" anpassen und die beiden Werte anpassen.

> user = pi
> 
> debug-level = 7

### editieren der ScanBd Konfiguration

Öffnen der scanbd.conf datei

>$ sudo nano /etc/scanbd/scanbd.conf

In dieser Datei müssen die folgenden Zeilen geändert werden :
Der Script Pfad sollte: scriptdir=/etc/scanbd/scripts sein.
Zusätzlich muss noch der scan cmd angepasst werden.

"action scan" 
- desc = "Scan to file on smb share"
- script = "scan.sh"

Create the dir
>$ sudo mkdir /etc/scanbd/scripts/

Create the File
>$ echo -e '#!/bin/sh\nscanimage > /media//foo.pnm' | sudo tee /etc/scanbd/scripts/scan.sh

Change the user rights
>$ sudo chmod a+x /etc/scanbd/scripts/scan.sh


ACHTUNG bis hier hin bin ich gekommen!!!

### Start des deamon's

>$ sudo scanbd -f




## SMB Client installieren
Damit wir auf unsere NAS zugreifen können benötigen wir einen SMB Client.

### Install CMD for the SMB Client
Hier wird der cifs client installiert.

>$ sudo apt install samba samba-common-bin smbclient cifs-utils

### Parametrieren 
Wir erstellen einen Ordern mit dem wir **dann** das Share mounten. Dieser wird /media/ScannerShare 
Bitte nicht im home Verzeichnis erstellen. Am meistens sinn macht dies im media Verzeichnis.

>$ mkdir /media/ScannerShare

Anschließend versuchen wir den Share zu mounten mit diesem befehl hier:

>$ sudo mount.cifs "//192.168.178.24/Privat Edu/Documents/Scanner" /media/ScannerShare -o user=ApplePi

Aber achtung in dem Aktuellen kernel von Linux rasbian wird SMB in der Verison 3 genutzt. Sollte explizit eine andere Version ausgewählt werden so muss diese angegeben.

>…annerShare - 0 user=ApplePi,vers=2.0

Damit sich sdas ganze aber auhc bei einem Reboot automatisch wieder verbindet müssen wir die Datei: "/etc/fstab" anpassen. Hierzu öffnen wir die Datei:

>$ sudo nano /etc/fstab

Anschließend fürgen wir die follgende Line hinzu:

> "//192.168.178.24/Privat\040Edu/Documents/Scanner" /media/ScannerShare cifs username=TheSmbServerUser,password=SmbPassword,uid=TheLocalUserWhoNeedsAccess,iocharset=utf8,file_mode=0777,dir_mode=0777,noperm 0 0

Achtung! Dieser zusatz hier wird benötigt damit das gemountete Verzeichnis auch von dem normalen pi user genutzt werden kann!
> ...,uid=TheLocalUserWhoNeedsAccess,iocharset=utf8,file_mode=0777,dir_mode=0777,noperm 0 0



Achtung! Bei Leerzeichen im Namen des Shared Folders müssen diese durch "\040" ersetzt werden.
Ich habe noch die Raspberry Pi Konfiguration angepasst damit das Booten erst weiter läuft wenn das Netzwerk vorhanden ist. Die Konfiguration können wir öffnen mit:

>$ sudo raspi-config

Dann können wir unter: /3 Boot Options/B2 Wait for Network at Boot/ Hier können wir dieses verhalten einschalten.





## Wichtige Terminal CMD's



### Auslesen der aktuellen Temperatur auf dem Bord
>$ vcgencmd measure_temp

### Installieren des Microsofts RemoteDesktops
>$ sudo apt-get install xrdp

### Unter der "hostname" Datei kann der Hostname des Raspberry pi's angepasst werden.

>$ sudo nano /etc/hostname
>
>$ sudo nano /etc/hosts




sudo chown -R pi /home/pi/ScannerShare
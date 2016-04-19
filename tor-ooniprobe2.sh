#!/bin/bash

#Zusammengeklaut von Marc Landolt jr
#==============================================================================
#title           :tor-with-ooniprobe-install.sh
#description     :This scirpt installs Tor and ooniprobe (Switzerland)
#author		 :Marc Landolt, @FailDef
#date            :20151212
#version         :0.2
#usage		 :bash tor-with-ooniprobe-install.sh
#notes           :
#bash_version    :4.3.30(1)-release
#==============================================================================

clear

#ein paar Leerzeilen anzeigen
for i in 1 2 3 4 5
  do echo " "
done


echo -e "
\e[36mAledged: die Leute die #ooniprobe aktiv verwenden werden von einem Agenten überwacht, aus erstem erfolgreichein Installieren wird
wird ein CogScience Virus geschrieben um andere beim Installieren auf falschen Pfad zu schicken und zu triggern => Aversion #tor #ooniprobe
so soll z.B. in der #Schweiz geheim bleiben dass die Überwachungsinfrastruktur eine #Zensur Infrastruktur ist #tor #ooniprobe
Pfad, z.B. die Webseiten wo man Fehlermeldungen nachliest wird vom CIA/NSA mit CogScience Malware/Sprengfallen (ev personifiziert) infiziert

für's Triggern mutmasslich Quantum/Resesarch/Group::TURBINE::qFire mit pulsed microwave verwendet der Epilepsieanfall verursachen
\e[39m

allenfalls /Kind/ dass auf dem Epilepsie schrott noch nicht angegriffen wird oder gleichaltriges /Kind/ / Ageplay Papi der resistent gegen den qFire mist kann helfen 
"


echo -e "Falls keine Debian CD vorhanden, bitte die Zeile mit \"deb cdrom....\" mit \"#deb cdrom....\" im \e[1m/etc/apt/sources.list\e[0m auskommentieren"
echo -e "mit der kombination  \e[36m[esc]i\e[39m schreibt man mit \e[36m[esc]:wq\e[39m speichert und beendet man"
echo " "
read -p "Bitte Taste drücken um die /etc/apt/sources.list zu editieren"

vi /etc/apt/sources.list

apt-get update

apt-get upgrade

apt-get install sudo vim


echo Beispiel Konfiguration für 2 Netzwerkkarten /etc/network/interfaces
echo -------------------------------------------------------------------
echo "# This file describes the network interfaces available on your system"
echo "# and how to activate them. For more information, see interfaces(5).
echo " "
echo "source /etc/network/interfaces.d/*"
echo " "
echo "# The loopback network interface"
echo "auto lo"
echo "iface lo inet loopback"
echo "
echo "# The primary network interface (LAN)"
echo "allow-hotplug eth0"
echo "iface eth0 inet static"
echo "  address 192.168.1.41"
echo "  netmask 255.255.255.0"
echo "# absichtlch kein Gateway"
echo " "
echo "# The secondary network interface (WAN, leider keine Statische IP im Budget)"
echo "allow-hotplug eth1"
echo "iface eth1 inet static"


echo "
# The primary network interface (LAN)
allow-hotplug eth0
iface eth0 inet static
  address 192.168.1.41
  netmask 255.255.255.0
  # absichtlch kein Gateway
  post-up route add -net 192.168.179.0/24 gw 192.168.1.1 dev eth0

# The secondary network interface (WAN)
allow-hotplug eth1
iface eth1 inet dhcp
" >>/etc/network/interfaces

sudo vim /etc/network/interfaces
sudo ifdown eth0
sudo ifdown eth1
sudo ifup eth0
sudo ifup eth1

echo "route zum zweiten Netz über die interne Netzwerkkarte hinzufügen (eth0)"
echo "route add -net 192.168.179.0/24 gw 192.168.1.1 dev eth0"

sudo route add -net 192.168.179.0/24 gw 192.168.1.1 dev eth0
echo

echo "Testen ob das Route zum Monitoring Server funktioniert: ping 192.168.179.222 -c3"
echo
ping 192.168.179.222 -c3
echo
echo

read -p "Bitte Taste drücken"
echo

echo "apt-get install tor tor-arm vim figlet"
sudo apt-get install tor tor-arm vim figlet

echo -e "\e[32m"
/usr/bin/figlet -w 180 tor und ooniprobe installieren
echo auf Debian jessie 8.1.0
echo -e "\e[0m"
echo
echo
echo "die beiden Ports 9030 (DirPort) und 9001 (ORPort) müssen im Portforwarding des Routers freigeschaltet sein oder das Gerät muss direkt am Netz hängen ohne Ruter dazwischen"
echo
echo
echo "Google Bildersuche: Port-Forwarding <Gerätetyp>"
echo "               z.B. Port-Forwarding zyxel USG100"
echo
echo
echo -e "\e[33m/etc/tor/torrc\e[39m"
echo -e "Bei den Zeilen \e[36mDirPort\e[39m und \e[36mORPort\e[39m den trailing hash (das # ganz am Anfang) löschen"
echo -e "Mit \e[36m[esc]i\e[39m schreibt man in die Datei mit \e[36m[esc]:wq\e[39m speichert man (Write) und schliesst (Quit) die Datei"
echo

echo -e "Datei \e[1m/etc/tor/torrc\e[0m zu editieren"
read -p "Bitte Taste drücken im mit vim die Datei /etc/tor/torrc zu editieren oder mit [ctrl-c] abbrechen"
echo

sudo vim /etc/tor/torrc
echo

echo "Tor restarten: \"/etc/init.d/tor restart\""
sudo /etc/init.d/tor restart
sudo /etc/init.d/tor status
echo

wait 10
tail /var/log/tor/log

sudo apt-get install python-pip python-dev libdumbnet1 libdumbnet-dev libpcap-dev
sudo apt-get purge python-pyasn1 
sudo pip install sip-dev
sudo pip install scapy pypcap txsocksx sip pyasn1
sudo pip install https://github.com/TheTorProject/ooni-probe/archive/master.zip

cd ~
mkdir my_decks
sudo ooniresources --update-inputs --update-geoip
oonideckgen -o my_decks/

#fuer die SCHWEIZ -> CH (Ländercode)
(crontab -l 2>/dev/null ; echo @daily /usr/local/bin/ooniprobe -i ~/my_decks/deck-ch/0.1.0-ch-user.deck) | crontab -


echo "http://www.marclandolt.ch" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt
echo "http://www.marclandolt.ch/ml_buzzernet" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt
echo "http://marclandolt.ch" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt
echo "http://marclandolt.ch/ml_buzzernet" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt
echo "http://www.ignored.ch" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt
echo "http://www.ignored.ch/ml_buzzernet" >> /root/my_decks/deck-ch/citizenlab-urls-global.txt

echo "Zabbix Agent installieren: apt-get install zabbix-agent"
sudo apt-get install zabbix-agent
echo
echo -e "im \e[1m/etc/zabbix/zabbix_agentd.conf\e[0m bei der Zeile \"\e[1mserver=192.168.179.222\e[0m\" den oder die zabbix Server eintragen (Es hat Kommentare im Konfig File)"
echo
read -p "Bitte Taste drücken"
vim /etc/zabbix/zabbix_agentd.conf

echo "Zabbix neu starten: \"/etc/init.d/zabbix_agentd restart\""
/etc/init.d/zabbix_agentd restart
/etc/init.d/zabbix_agentd status

apt-get install snmpd snmp
echo
echo -e "\e[36mAnpassungen in snmpd.conf\e[39m"
echo --------------------------
echo -e "\e[1magentAddress 192.168.1.41:161\e[0m"
echo das ist die Netzwerkkarte im internen Netzwerk wo mein Monitoring läuft
echo
echo -e "\e[1mrocommunity public localhost\e[0m"
echo -e "\e[1mrocommunity public 192.168.1.0/24\e[0m"
echo -e "\e[1mrocommunity public 192.168.179.0/24\e[0m"
echo "das sind die die da zugreifen können, security mässig bisschen viel, und man könnte auch noch passworte setzen, aber ist halt quick&dirthy"
echo
read -p "Bitte Taste drücken"


vim /etc/snmp/snmpd.conf
/etc/init.d/snmpd restart
/etc/init.d/snmpd status


/usr/bin/snmpwalk -v2c -cpublic 192.168.1.41 iso.3.6.1.2.1.1


/usr/local/bin/ooniprobe -i ~/my_decks/deck-ch/0.1.0-ch-user.deck


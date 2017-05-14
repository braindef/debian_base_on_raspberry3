#!/bin/bash

echo not working yet
exit 0

# Script Debian Base on Raspberry PI3 from AMD64 machine
#==============================================================================
#title           :
#description     :
#author		 :Marc Landolt, @FailDef
#date            :
#version         :0.1
#usage		 :
#notes           :
#bash_version    :
#==============================================================================
#
# by Klaus M Pfeiffer, http://blog.kmp.or.at/ , 2012-06-24 
# 
# 2017-05-14 Mj.Landolt - updated to Debian Stretch 
# 2016-03-12 Mj.Landolt - updated to Debian Jessie 
# 
# 2014-07-20 J.Mattsson - fixes to get current rpi-update to work 
# 2014-06-28 J.Mattsson - added early exit on error 
#                       - added --no-check-gpg to debootstrap 
#                       - made release name (wheezy) a mere default 
# 2013-08-25 J.Mattsson - trimmed down further and changed to raspbian armhf 
#  
 
# 2012-06-24 
#       just checking for how partitions are called on the system (thanks to Ricky Birtles and Luke Wilkinson) 
#       using http.debian.net as debian mirror, see http://rgeissert.blogspot.co.at/2012/06/introducing-httpdebiannet-debians.html
#       tested successfully in debian squeeze and wheezy VirtualBox
#       added hint for lvm2
#       added debconf-set-selections for kezboard
#       corrected bug in writing to etc/modules
# 2012-06-16
#       improoved handling of local debian mirror
#       added hint for dosfstools (thanks to Mike)
#       added vchiq & snd_bcm2835 to /etc/modules (thanks to Tony Jones)
#       take the value fdisk suggests for the boot partition to start (thanks to Mike)
# 2012-06-02
#       improoved to directly generate an image file with the help of kpartx
#       added deb_local_mirror for generating images with correct sources.list
# 2012-05-27
#       workaround for https://github.com/Hexxeh/rpi-update/issues/4 just touching /boot/start.elf before running rpi-update
# 2012-05-20
#       back to wheezy, http://bugs.debian.org/672851 solved, http://packages.qa.debian.org/i/ifupdown/news/20120519T163909Z.html
# 2012-05-19
#       stage3: remove eth* from /lib/udev/rules.d/75-persistent-net-generator.rules
#       initial



# Define Editor
#==============================================================================
#EDITOR=$(which nano)
EDITOR=$(which vim)
#==============================================================================


# Color Definitions
#==============================================================================
red="\e[91m"
default="\e[39m"
#==============================================================================


# Define which Linux Distribution
#==============================================================================
#distro=jessie
distro=stretch
${deb_release:="stretch"} 
#==============================================================================

bootsize="64M"
# Define other variables used later in this script 
#==============================================================================
device=$1 
buildenv="$(pwd)/image" 
rootfs="${buildenv}/rootfs" 
bootfs="${rootfs}/boot" 
mydate=`date +%Y%m%d`
#==============================================================================


# Define which mirror for the repository
#==============================================================================
#deb_mirror="http://mirror.internode.on.net/pub/raspbian/raspbian/" 
deb_mirror="http://httpredir.debian.org/debian" 
#deb_local_mirror="http://debian.kmp.or.at:3142/debian"
#deb_mirror="http://armbian.org/
#==============================================================================



# Helper Function to show first the command that is beeing executed
#==============================================================================
function ShowAndExecute {
	#show command
	echo -e "${red} $1 ${default}"
	#execute command
	$1
	#test if it worked or give an ERROR Message in red, return code of apt is stored in $?
	rc=$?; if [[ $rc != 0 ]]; then echo -e ${red}ERROR${default} $rc; fi


# Helper Function to show first the command that is beeing executed
#==============================================================================
function ShowAndExecute {
	#show command
	echo -e "${red} $1 ${default}"
	#execute command
	$1
	#test if it worked or give an ERROR Message in red, return code of apt is stored in $?
	rc=$?; if [[ $rc != 0 ]]; then echo -e ${red}ERROR${default} $rc; fi
}
##test if everything worked
#==============================================================================


# Helper Function for YES or NO Answers
#------------------------------------------------------------------------------
# Example YESNO "Question to ask" "command to be executed"
#==============================================================================
function YESNO {
	echo -e -n "
	${red}$1 [y/N]${default} "
	read -d'' -s -n1 answer
	echo
	if  [ "$answer" = "y" ] || [ "$answer" = "Y" ]
	then
		return 0
	else
		echo -e "
		"
		return 1
	fi
}
#==============================================================================


# Test if script runs as root otherweise exit with exit code 1
#==============================================================================
if [[ $EUID -ne 0 ]]; then
	  echo -e -n "
	  ${red}You must be a root user to run this script${default}
	  at the moment you are " 2>&1
	    id | cut -d " " -f1
	      echo
	        exit 1
	fi
	#==============================================================================


	# Test if user has given enough parameters
	#==============================================================================
	if "$1" = ""
	then
		echo -e "
		Usage:
		------
		Enter the device where you want to write the image to ${red}sudo ${0} /dev/sdb${default} or ${red}sudo ${0} /dev/mmcblk0${default} or something else "
		echo
		echo " arguments ---------------->  ${@}     "
		echo " \$1 ----------------------->  $1       "
		echo " \$2 ----------------------->  $2       "
		echo " path to script ----------->  ${0}     "
		echo " parent path -------------->  ${0%/*}  "
		echo " script name -------------->  ${0##*/} "
		echo
		exit 0
	fi
	#==============================================================================

	echo -e "${red}${0} ${@}${default}"

	# get the newest updates
	#==============================================================================



	ShowAndExecute "umount ${1}*1"
	ShowAndExecute "umount ${1}*2"
	ShowAndExecute "umount ${1}*3"
	ShowAndExecute "umount ${1}*4"

        echo installing required packages on AMD64 Machine
	ShowAndExecute "apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools"
	
	ShowAndExecute "cat -e /var/lib/dpkg/lock"

	ShowAndExecute "dpkg --configure -a"

	ShowAndExecute "apt --fix-broken install"

	ShowAndExecute "apt-get -y update"

	ShowAndExecute "apt-get -y upgrade"

	ShowAndExecute "apt-get -y dist-upgrade"

	ShowAndExecute "apt-get -y install sudo git vim nano"
	#==============================================================================

	# edit repository list
	#==============================================================================
	if YESNO "Edit /etc/apt/sources.list?"
	then
		ShowAndExecute "$EDITOR /etc/apt/sources.list"
	fi

	if YESNO "Use TOR (The Onion Router) for APT Transport?"
	then

		  ShowAndExecute "apt-get -y install torsocks apt-transport-tor"

		    cp /etc/apt/sources.list /etc/apt/sources.list-$(date +%Y%m%d-%H%M%S.bak)
		      echo "
		      deb tor+http://vwakviie2ienjx6t.onion/debian/ $codename main contrib
		      deb tor+http://earthqfvaeuv5bla.onion/debian/ $codename main contrib
		      " > /etc/apt/sources.list

		      ShowAndExecute "apt-get -y update"

		      ShowAndExecute "apt-get -y upgrade"

		      ShowAndExecute "apt-get -y install tor tor-arm"
	      fi

	      if YESNO "Use normal httpredir.debian.org for APT Transport?"
	      then
		        cp /etc/apt/sources.list /etc/apt/sources.list-$(date +%Y%m%d-%H%M%S.bak)
			  echo "
			  deb http://httpredir.debian.org/debian/ $distro main contrib
			  deb-src http://httpredir.debian.org/debian/ $distro main contrib
			  deb http://security.debian.org/ $distro/updates main contrib
			  deb-src http://security.debian.org/ $distro/updates main contrib
			  deb http://httpredir.debian.org/debian/ $distro-updates main contrib
			  deb-src http://httpredir.debian.org/debian/ $distro-updates main contrib
			  " >/etc/apt/sources.list

		  fi

		  # edit repository list after modification
		  #==============================================================================
		  if YESNO "Edit /etc/apt/sources.list?"
		  then
			  ShowAndExecute "$EDITOR /etc/apt/sources.list"

			  ShowAndExecute "apt-get -y update"

			  ShowAndExecute "apt-get -y upgrade"
		  fi

		  # edit repository list after modification
		  #==============================================================================
		  ShowAndExecute "apt-get -y install md5deep"
		  ShowAndExecute "apt-get -y install rdfind"
		  ShowAndExecute "apt-get -y install nmap"
		  ShowAndExecute "apt-get -y install rsync"
		  ShowAndExecute "apt-get -y install snmp"
		  ShowAndExecute "apt-get -y install jigdo-file"
		  ShowAndExecute "apt-get -y install build-essential"
		  ShowAndExecute "apt-get -y install pkg-config "
		  ShowAndExecute "apt-get -y install libdbus-1-dev"
		  ShowAndExecute "apt-get -y install apt-file"
		  ShowAndExecute "apt-file update"
		  ShowAndExecute "apt-get -y install figlet"
		  ShowAndExecute "apt-get -y install git"
		  ShowAndExecute "apt-get -y install tcpdump"
		  ShowAndExecute "apt-get -y install iptraf"
		  ShowAndExecute "apt-get -y install gparted"
		  ShowAndExecute "apt-get -y install lightdm lxde"
		  ShowAndExecute "apt-get -y install gdm3 gnome gnome-shell"
		  ShowAndExecute "apt-get -y install gconf-editor"
		  ShowAndExecute "gsettings set org.gnome.nautilus.preferences always-use-location-entry true"
		  ShowAndExecute "apt-get -y install chromium"
		  ShowAndExecute "apt-get -y install inkscape"
		  ShowAndExecute "apt-get -y install gimp"
		  ShowAndExecute "apt-get -y install libreoffice"
		  ShowAndExecute "apt-get -y install libreoffice-help-de"
		  ShowAndExecute "apt-get -y install libreoffice-l10n-de"
		  ShowAndExecute "apt-get -y install cups-pdf"
		  ShowAndExecute "apt-get -y install keepassx "
		  ShowAndExecute "apt-get -y install icedove"
		  ShowAndExecute "apt-get -y install vlc"
		  ShowAndExecute "apt-get -y install kdenlive"
		  ShowAndExecute "apt-get -y install screenkey"
		  ShowAndExecute "apt-get -y install simplescreenrecorder"
		  ShowAndExecute "apt-get -y install virtualbox"

		  #ShowAndExecute "apt-get -y install audacity"
		  #ShowAndExecute "apt-get -y install lmms" +ladspa delay zynfx?

		  ShowAndExecute "apt-get -y install posterazor"
		  ShowAndExecute "apt-get -y install gconf-editor"
		  ShowAndExecute "apt-get -y install mumble"
		  ShowAndExecute "apt-get -y install font-manager"
		  ShowAndExecute "apt-get -y install quassel "
		  ShowAndExecute "apt-get -y install pidginnnnnnn"

		  #ShowAndExecute "apt-get -y install xserver-xorg-input-all"
		  #ShowAndExecute "apt-get -y install gnome-commander"
		  #ShowAndExecute "#apt-get -y install mc"
		  #ShowAndExecute "#apt-get -y install xsane"
		  #ShowAndExecute "apt-get -y install redshift"
		  #ShowAndExecute "apt-get -y install extundelete"
		  #ShowAndExecute "apt-get -y install qrencode "
		  #ShowAndExecute "apt-get -y install apt-xapian-index"

		  #printf "install pamusb (y/n)"
		  #gparted
		  #/usr/bin/pamusb-conf --add-device seven
		  #/usr/bin/pamusb-conf --add-user $(id -u 1000 -n)

		  #printf "install tripwire?"
		  #echo -e "Benutzer \e[92mguest\e[39m erstellen mit zweitem mini MemoryStick, den man auch stecken lassen kann und keine Admin-rechte hat (y/n)?"

		  #echo -e "generell Bunt einschalten im vim"
		  #echo "syntax on" >>$HOME/.vimrc
		  #printf "install torbrowser-launcher non-free"

		  ShowAndExecute "apt-get autoremove"


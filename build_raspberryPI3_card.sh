#!/bin/bash

echo not working yet
#exit 0

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
defaultColor="\e[39m"
#==============================================================================


# Define which Linux Distribution
#==============================================================================
#deb_release="jessie"
deb_release="stretch"
#==============================================================================

bootsize="64M"
# Define other variables used later in this script 
#==============================================================================
device=$1 
buildenv="$(pwd)/image" 
rootfs="${buildenv}/rootfs" 
bootfs="${rootfs}/boot" 
mydate=`date +%Y%m%d`
image=""
#==============================================================================


# Define which mirror for the repository
#==============================================================================
#deb_mirror="http://mirror.internode.on.net/pub/raspbian/raspbian/" 
deb_mirror="http://httpredir.debian.org/debian" 
#deb_local_mirror="http://debian.kmp.or.at:3142/debian"
#deb_mirror="http://armbian.org/"
#==============================================================================


# Define which component for the repository
#==============================================================================
component="main contrib"                                    #debian
#component="main restricted universe multiverse"            #ubuntu

# Helper Function to show first the command that is beeing executed
#==============================================================================
function ShowAndExecute {
	#show command
	echo -e "${red}$1 ${defaultColor}"
	#execute command
	$1
	#test if it worked or give an ERROR Message in red, return code of apt is stored in $?
	rc=$?; if [[ $rc != 0 ]]; then echo -e ${red}ERROR${defaultColor} $rc; fi
}
#==============================================================================


# Helper Function for YES or NO Answers
#------------------------------------------------------------------------------
# Example YESNO "Question to ask" "command to be executed"
#==============================================================================
function YESNO {
	echo -e -n "
	${red}$1 [y/N]${defaultColor} "
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
	${red}You must be a root user to run this script${defaultColor}
	at the moment you are " 2>&1
	id | cut -d " " -f1
	echo
	exit 1
fi
#==============================================================================


# Test if user has given enough parameters
#==============================================================================
if [ "$1" = "" ]
then
	echo -e "
Usage:
------
Enter the device where you want to write the image to eg:
${red}sudo ${0} /dev/sdb${defaultColor} (for USB SD-Card Adapter) or
${red}sudo ${0} /dev/mmcblk0${defaultColor} (for a builtin SD-Card Adapter) or
${red}sudo ${0} image${defaultColor} (if you want just an image) or
something else "
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

echo -e "${red}${0} ${@}${defaultColor}"


echo installing required packages on AMD64 Machine
ShowAndExecute "apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools"

ShowAndExecute "umount ${1}*"

# Image, /dev/mmcblk* or /dev/sd* ?
#==============================================================================
if [ "$1" = "image" ]
then
	echo -e "${red}no block device given, just creating an image${defaultColor}"

	mkdir -p $buildenv

	image="${buildenv}/raspbian_base_${deb_release}_${mydate}.img"

	dd if=/dev/zero of=$image bs=1MB count=1000

	device=`losetup -f --show $image`

	echo -e "${red}image $image created and mounted as $device${defaultColor}"

	echo -e "o\nn\np\n1\n\n+${bootsize}\ny\nt\nc\np\nn\np\n2\n\n\ny\np\nw" | fdisk $device

	losetup -d $device

	device=`kpartx -sva $image | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`

	device="/dev/mapper/${device}"
	boot_partition="${device}p1"  
	root_partition="${device}p2"
fi

if [[ $1 == *"mmc"* ]]
then
	boot_partition=${device}p1  
	root_partition=${device}p2 
	device=$1
	echo -e "${red}fdisk $device creating new DOS Partition${defaultColor}"
	echo -e "o\nn\np\n1\n\n+${bootsize}\ny\nt\nc\np\nn\np\n2\n\n\ny\np\nw" | fdisk $device
fi

if [[ $1 == *"sd"* ]]
then
	boot_partition=${device}1  
	root_partition=${device}2
	device=$1
	echo -e "${red}fdisk $device creating new DOS Partition${defaultColor}"
	echo -e "o\nn\np\n1\n\n+${bootsize}\ny\nt\nc\np\nn\np\n2\n\n\ny\np\nw" | fdisk $device
fi

#==============================================================================


ShowAndExecute "mkfs.vfat $boot_partition"
ShowAndExecute "mkfs.ext4 $root_partition"

ShowAndExecute "mkdir -p $rootfs"

ShowAndExecute "mount $root_partition $rootfs"

ShowAndExecute "cd $rootfs"

ShowAndExecute "debootstrap  --foreign --arch armhf $deb_release $rootfs $deb_mirror"
#debootstrap  --foreign --arch arm64 $deb_release $rootfs $deb_local_mirror

ShowAndExecute "cp /usr/bin/qemu-arm-static usr/bin/"
LANG=C chroot $rootfs debootstrap/debootstrap --second-stage

ShowAndExecute "mount $boot_partition $bootfs"

echo "
deb $deb_mirror $deb_release $component
deb-src $deb_mirror $deb_release $component

deb http://security.debian.org/ $deb_release/updates $component
deb-src http://security.debian.org/ $deb_release/updates $component

deb $deb_mirror $deb_release-updates $component
deb-src $deb_mirror $deb_release-updates $component

" > etc/apt/sources.list

echo "${red}dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait${defaultColor}"
echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" > boot/cmdline.txt

echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults        0       0
/dev/mmcblk0p2  /           ext4    defaults        0       0
" > etc/fstab

echo "debian" > etc/hostname

echo "auto lo 
iface lo inet loopback 
 
auto eth0 
iface eth0 inet dhcp 
" > etc/network/interfaces 
 
echo "vchiq 
snd_bcm2835 
" >> etc/modules 
 
echo "#!/bin/bash 
apt-get update  
apt-get -y install --no-install-recommends git-core binutils ca-certificates curl net-tools usbutils 
" > third-stage

echo "
wget https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update 
chmod +x /usr/bin/rpi-update 
" >> third-stage

echo "
mkdir /lib/modules 
touch /boot/start.elf 
SKIP_BACKUP=1 rpi-update 
" >> third-stage

echo "
apt-get -y install ntp openssh-server less vim 

echo \"root:root\" | chpasswd 
" >>third-stage

echo "
echo 'SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"*\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"'>>/etc/udev/rules.d/70-persistent-net.rules" >> third-stage


echo "
echo
echo \"echo edit your networkinterfaces /etc/udev/rules.d/70-persistent-net.rules: 

/sbin/udevadm info -e | grep ID_NET_NAME 
\" >>/root/.profile " >> third-stage 

ShowAndExecute "chmod +x third-stage" 
LANG=C chroot $rootfs /third-stage


echo "#!/bin/bash
apt-get clean
rm -f cleanup
" > cleanup
chmod +x cleanup
LANG=C chroot $rootfs /cleanup

cd

sync

umount $boot_partition
umount $root_partition

if [ "$image" != "" ]; then
	kpartx -d $image
	echo "created image $image"
fi


echo have fun...



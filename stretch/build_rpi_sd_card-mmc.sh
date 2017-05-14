#!/bin/bash

# build your own Raspberry Pi SD card
#
# by Klaus M Pfeiffer, http://blog.kmp.or.at/ , 2012-06-24
#
# 2016-03-12 Mj.Landolt - updated to Debian Jessie by Marc Landolt, http://www.marclandolt.ch/#mindhacking , 2016-03-12
#
# 2014-07-20 J.Mattsson - fixes to get current rpi-update to work
# 2014-06-28 J.Mattsson - added early exit on error
#                       - added --no-check-gpg to debootstrap
#                       - made release name (wheezy) a mere default
# 2013-08-25 J.Mattsson - trimmed down further and changed to raspbian armhf
# 

# 2012-06-24
#	just checking for how partitions are called on the system (thanks to Ricky Birtles and Luke Wilkinson)
#	using http.debian.net as debian mirror, see http://rgeissert.blogspot.co.at/2012/06/introducing-httpdebiannet-debians.html
#	tested successfully in debian squeeze and wheezy VirtualBox
#	added hint for lvm2
#	added debconf-set-selections for kezboard
#	corrected bug in writing to etc/modules
# 2012-06-16
#	improoved handling of local debian mirror
#	added hint for dosfstools (thanks to Mike)
#	added vchiq & snd_bcm2835 to /etc/modules (thanks to Tony Jones)
#	take the value fdisk suggests for the boot partition to start (thanks to Mike)
# 2012-06-02
#       improoved to directly generate an image file with the help of kpartx
#	added deb_local_mirror for generating images with correct sources.list
# 2012-05-27
#	workaround for https://github.com/Hexxeh/rpi-update/issues/4 just touching /boot/start.elf before running rpi-update
# 2012-05-20
#	back to wheezy, http://bugs.debian.org/672851 solved, http://packages.qa.debian.org/i/ifupdown/news/20120519T163909Z.html
# 2012-05-19
#	stage3: remove eth* from /lib/udev/rules.d/75-persistent-net-generator.rules
#	initial

# you need at least

umount ${1}p1
umount ${1}p2

read -p "Installing Debian Packages, please press [ANYKEY]"
echo

apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools

#deb_mirror="http://mirror.internode.on.net/pub/raspbian/raspbian/"
deb_mirror="http://httpredir.debian.org/debian"
#deb_local_mirror="http://debian.kmp.or.at:3142/debian"

bootsize="64M"
: ${deb_release:="stretch"}

echo "Using Debian release: $deb_release"

device=$1
buildenv="$(pwd)/image"
rootfs="${buildenv}/rootfs"
bootfs="${rootfs}/boot"

mydate=`date +%Y%m%d`

if [ "$deb_local_mirror" == "" ]; then
  deb_local_mirror=$deb_mirror  
fi

image=""


if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1
fi

if ! [ -b $device ]; then
  echo "$device is not a block device"
  exit 1
fi

if [ "$device" == "" ]; then
  echo "no block device given, just creating an image"
  mkdir -p $buildenv
  image="${buildenv}/raspbian_base_${deb_release}_${mydate}.img"
  dd if=/dev/zero of=$image bs=1MB count=1000
  device=`losetup -f --show $image`
  echo "image $image created and mounted as $device"
else
  dd if=/dev/zero of=$device bs=512 count=1
fi

echo fdisk $device creating new DOS Partition
fdisk $device << EOF
o

w

EOF

echo fdisk $device
fdisk $device << EOF
n
p
1

+$bootsize
t
c
n
p
2


w
EOF

set -e

if [ "$image" != "" ]; then
  losetup -d $device
  device=`kpartx -sva $image | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
  device="/dev/mapper/${device}"
  boot_partition=${device}p1
  root_partition=${device}p2
else
  if ! [ -b ${device}1 ]; then
    boot_partition=${device}p1
    root_partition=${device}p2
    if ! [ -b ${boot_partition} ]; then
      echo "uh, oh, something went wrong, can't find boot_partitionartition neither as ${device}p1 nor as ${device}p1, exiting."
      exit 1
    fi
  else
    boot_partition=${device}p1
    root_partition=${device}p2
  fi  
fi

echo mkfs.vfat $boot_partition
echo mkfs.ext4 $root_partition

mkfs.vfat $boot_partition
mkfs.ext4 $root_partition

mkdir -p $rootfs

mount $root_partition $rootfs

cd $rootfs

debootstrap  --foreign --arch armhf $deb_release $rootfs $deb_local_mirror
#debootstrap  --foreign --arch arm64 $deb_release $rootfs $deb_local_mirror
cp /usr/bin/qemu-arm-static usr/bin/
LANG=C chroot $rootfs debootstrap/debootstrap --second-stage

mount $boot_partition $bootfs

echo "
deb http://httpredir.debian.org/debian/ $deb_release main contrib
deb-src http://httpredir.debian.org/debian/ $deb_release main contrib

deb http://security.debian.org/ $deb_release/updates main contrib
deb-src http://security.debian.org/ $deb_release/updates main contrib

deb http://httpredir.debian.org/debian/ $deb_release-updates main contrib
deb-src http://httpredir.debian.org/debian/ $deb_release-updates main contrib


" > etc/apt/sources.list

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
#das dann später raus nehmen
wget https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update
#wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update
chmod +x /usr/bin/rpi-update
mkdir /lib/modules
touch /boot/start.elf
SKIP_BACKUP=1 rpi-update
apt-get -y install ntp openssh-server less vim
echo \"root:root\" | chpasswd
echo 'SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"*\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"'>>/etc/udev/rules.d/70-persistent-net.rules 
echo \"echo edit your networkinterfaces /etc/udev/rules.d/70-persistent-net.rules:
/sbin/udevadm info -e | grep ID_NET_NAME
\" >>/root/.profile
" > third-stage
chmod +x third-stage
LANG=C chroot $rootfs /third-stage

#echo "deb $deb_mirror $deb_release main contrib non-free
#" > etc/apt/sources.list


echo "
deb http://httpredir.debian.org/debian/ $deb_release main contrib
deb-src http://httpredir.debian.org/debian/ $deb_release main contrib

deb http://security.debian.org/ $deb_release/updates main contrib
deb-src http://security.debian.org/ $deb_release/updates main contrib

deb http://httpredir.debian.org/debian/ $deb_release-updates main contrib
deb-src http://httpredir.debian.org/debian/ $deb_release-updates main contrib

" > etc/apt/sources.list

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


echo "have fun..."

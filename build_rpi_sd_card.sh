#!/bin/bash

# build your own Raspberry Pi SD card
#
# by Klaus M Pfeiffer, http://blog.kmp.or.at/ , 2012-06-24
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
# apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools

deb_mirror="http://mirror.internode.on.net/pub/raspbian/raspbian/"
#deb_mirror="http://http.debian.net/debian"
#deb_local_mirror="http://debian.kmp.or.at:3142/debian"

bootsize="64M"
: ${deb_release:="wheezy"}

echo "Using Debian release: $deb_release"

device=$1
buildenv="/root/rpi"
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
  bootp=${device}p1
  rootp=${device}p2
else
  if ! [ -b ${device}1 ]; then
    bootp=${device}p1
    rootp=${device}p2
    if ! [ -b ${bootp} ]; then
      echo "uh, oh, something went wrong, can't find bootpartition neither as ${device}1 nor as ${device}p1, exiting."
      exit 1
    fi
  else
    bootp=${device}1
    rootp=${device}2
  fi  
fi

mkfs.vfat $bootp
mkfs.ext4 $rootp

mkdir -p $rootfs

mount $rootp $rootfs

cd $rootfs

debootstrap --no-check-gpg --foreign --arch armhf $deb_release $rootfs $deb_local_mirror
cp /usr/bin/qemu-arm-static usr/bin/
LANG=C chroot $rootfs /debootstrap/debootstrap --second-stage

mount $bootp $bootfs

echo "deb $deb_local_mirror $deb_release main contrib non-free
" > etc/apt/sources.list

echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" > boot/cmdline.txt

echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults        0       0
" > etc/fstab

echo "raspbian" > etc/hostname

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
apt-get -y install --no-install-recommends git-core binutils ca-certificates curl
wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update
chmod +x /usr/bin/rpi-update
mkdir /lib/modules
touch /boot/start.elf
SKIP_BACKUP=1 rpi-update
apt-get -y install ntp openssh-server less vim
echo \"root:raspberry\" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f third-stage
" > third-stage
chmod +x third-stage
LANG=C chroot $rootfs /third-stage

echo "deb $deb_mirror $deb_release main contrib non-free
" > etc/apt/sources.list

echo "#!/bin/bash
apt-get clean
rm -f cleanup
" > cleanup
chmod +x cleanup
LANG=C chroot $rootfs /cleanup

cd

umount $bootp
umount $rootp

if [ "$image" != "" ]; then
  kpartx -d $image
  echo "created image $image"
fi


echo "done."


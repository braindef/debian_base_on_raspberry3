debian_base_on_raspberry3
=========================
## partitially working on Debian Jessie 
installs Debian Jessie for ARM you can do this eg with an AMD64 machine, uses debootstrap
### Login credentials: root / root

**start with**: sudo ./build_rpi_sd_card.sh /dev/mmcblk0 (on an Intel or AMD Computer with plugged in microSDCard for Raspi3)

-then you can boot it in your Raspi3

To select your keyboard:

**apt-cache search keyboard** 

**apt-get install console-setup** (that lets you select your keyboard and language, takes about 1Min.) 

-than you can install a Graphical environment with:

**apt-get install lxde** 
it takes forever (2h) so plan eg to bake a cake during this part of the installation, since it's not funny watching 2h packages installing... 

TODO: Test with ARM64 (since this shall give more performance)

      WiFi

      other Drivers like sound

      seems to work also with debian stretch too :%s/jessie/stretch/g (vim) but without network eth0 nor wifi

      (maybe --2016-03-20 22:38:26--  https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update
      not yet compatible stretch kernel) but it boots...

Based on raspbain script from jmattson, TNX jmattson and Klaus M Pfeiffer.:

rasbian_base
============
Since I frequently find myself wanting a minimal base installation of Raspbian
for my various Raspberry Pi based projects, I ended up creating this one.

This Raspbian installation is pretty much the bare minimum, containing only
the SSH server, NTP server, less, vim and, of course, rpi-update.

The basis for the generation of this image is the very useful
"build_rpi_sd_card.sh" script by Klaus M Pfeiffer (http://blog.kmp.or.at).
I have tweaked it to use Raspbian rather than Debian, and hardware
floating-point rather than software emulation. Also, I removed a few more
packages which I didn't consider necessary.

Login credentials: root/root

Resizing the root partition
===========================
The image is a measly 1GB in size, which may not be enough for your needs.
You can either resize the root partition before you write it to an SD card,
or once you have booted it. For the latter option, below is a transcript of
how to do so:
```
root@raspbian:~# fdisk /dev/mmcblk0

Command (m for help): p

Disk /dev/mmcblk0: 3965 MB, 3965190144 bytes
4 heads, 16 sectors/track, 121008 cylinders, total 7744512 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0xe4304b18

        Device Boot      Start         End      Blocks   Id  System
/dev/mmcblk0p1            2048      133119       65536    c  W95 FAT32 (LBA)
/dev/mmcblk0p2          133120     1953124      910002+  83  Linux

Command (m for help): d
Partition number (1-4): 2

Command (m for help): n
Partition type:
   p   primary (1 primary, 0 extended, 3 free)
   e   extended
Select (default p): 
Using default response p
Partition number (1-4, default 2): 
Using default value 2
First sector (133120-7744511, default 133120): 
Using default value 133120
Last sector, +sectors or +size{K,M,G} (133120-7744511, default 7744511): 
Using default value 7744511

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.

WARNING: Re-reading the partition table failed with error 16: Device or resource busy.
The kernel still uses the old table. The new table will be used at
the next reboot or after you run partprobe(8) or kpartx(8)
Syncing disks.
root@raspbian:~# reboot
Broadcast message from root@raspbian (pts/0) (Sun Aug 25 05:09:46 2013):

The system is going down for reboot NOW!

... <wait for raspberry to reboot, then log back in> ...

root@raspbian:~# resize2fs /dev/mmcblk0p2 
resize2fs 1.42.5 (29-Jul-2012)
Filesystem at /dev/mmcblk0p2 is mounted on /; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/mmcblk0p2 is now 951424 blocks long.
```
Note that it is critical the replacement partition starts at the same block as
the old partition. In this case fdisk does the right thing by default, but if
you're doing this elsewhere, don't rely on it!

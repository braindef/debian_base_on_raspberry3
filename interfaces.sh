#!/bin/bash

date >>~/interface.log

/bin/ping -c 1 91.138.1.128
if [ "$?" = 0 ]
then
  echo eth1 online
  echo eth1 online >>~/interface.log
else
  echo eth1 offline
  echo eth1 offline >>~/interface.log
  /sbin/ifdown eth1
  /sbin/ifup eth1
fi

/bin/ping -c 1 192.168.1.1 

if [ "$?" = 0 ]
then
  echo eth0 online
  echo eth0 online >>~/interface.log
else
  echo eth0 offline
  echo eth0 online >>~/interface.log
  /sbin/ifdown eth0
  /sbin/ifup eth0
fi


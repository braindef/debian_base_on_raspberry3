#!/bin/sh

apt-get install torsocks apt-transport-tor

mv /etc/apt/sources.list /etc/apt/sources.list--backup1
echo "
deb tor+http://vwakviie2ienjx6t.onion/debian/ jessie main contrib
deb tor+http://earthqfvaeuv5bla.onion/debian/ jessie main contrib
" >> /etc/apt/sources.list

apt-get update
apt-get install vcsh


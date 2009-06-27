#!/bin/sh

# Copyright (c) 2006-2009 Konstantin Saurbier 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.


# Initialize variable with default values
PREFIX="/usr/local/sysstat"
GRAPHDIR="$PREFIX/output"
DBDIR="$PREFIX/db"
STEP=300
GINTERVAL=900

# Read arguments
while getopts hI:O: ARGS; do
    case $ARGS in
        h)
            # Display help
            echo ""
            echo "System statistics install-script"
            echo ""
            echo "Usage:"
            echo " -h       Display this help screen"
            echo " -I <path>    Install directory"
            echo "          (Default: /usr/local/sysstat)"
            echo " -O <path>    Where to write the statistics"
            echo "          (Default: $PREFIX/output)"
            exit
            ;;
        I)
            PREFIX="$OPTARG"
            ;;
        O)
            GRAPHDIR="$OPTARG"
            ;;
    esac
done

# Prepare variables
PREFIX=$(echo $PREFIX | sed "s:*/$::")
CONF="$PREFIX/etc/sysstat.conf.rb"
DBDIR="$PREFIX/db"
GRAPHDIR=$(echo $GRAPHDIR | sed "s:*/$::")

# Get Ram, Swap and OS
if [ `uname -s` = "FreeBSD" ]; then
    RAM=$(($(sysctl -n hw.physmem) / 1024))
    SWAP=$(swapinfo -k | tail -1 | awk '{print $2}')
    OS="freebsd6"
elif [ `uname -s` = "Linux" ]; then
    RAM=$(cat /proc/meminfo | grep -w "MemTotal:" | awk '{print $2}')
    SWAP=$(cat /proc/meminfo | grep -w "SwapTotal:" | awk '{print $2}')
    OS="linux2.6"
fi

# Get hard disks
DISKS=$(mount | egrep -v "proc|devfs|udev|tmpfs|sysfs|usbfs|devpts|nfs|autofs")
HDDS=$(echo "$DISKS" | cut -f1 -d" " | cut -f3 -d"/" | tr "\n" " " | sed 's: $::')
MOUNTS=$(echo "$DISKS" | cut -f3 -d" ")

HDD="  - $(echo "$HDDS" | sed 's/ /\
  - /g')"

TMP=""
i=0
for part in $HDD; do
  j=0
  for mp in $MOUNTS; do
    if [ "$i" = "$j" ]; then
      TMP="$TMP    $part: $mp
"
    fi
    j=$(($j + 1))
  done
  i=$((i+1))
done

MOUNTS=$TMP


# Get network interfaces
INTERFACES=$(ifconfig | grep -v lo | egrep "^[a-z].*" | tr -s "[:space:]" | cut -f1 -d" " | \
        tr -d ":" | tr "\n" " " | sed 's: $::')
INTERCONF="  - $(echo "$INTERFACES" | sed 's/ /\
  - /g')"

# Create temporary files and directories
mkdir -p tmp

# Create configuration file
cat src/conf/sysstat.part1.yml | \
    sed "s:OS:$OS:" | \
    sed "s:INSTALLDIR:$PREFIX:" | \
    sed "s:GRAPHDIR:$GRAPHDIR:" | \
    sed "s:DBDIR:$DBDIR:" > tmp/sysstat.yml
echo "$HDD" >> tmp/sysstat.yml
echo "
  mounts: " >> tmp/sysstat.yml
echo "$MOUNTS" >> tmp/sysstat.yml
cat src/conf/sysstat.part2.yml | \
    sed "s:RAM:$RAM:" | \
    sed "s:SWAP:$SWAP:" >> tmp/sysstat.yml
echo "$INTERCONF" >> tmp/sysstat.yml
cat src/conf/sysstat.part3.yml >> tmp/sysstat.yml

# Create daemon
sed "s:INSTALLDIR:$PREFIX:" src/bin/sysstat.rb > tmp/sysstat.rb

# Create classes
for i in $(ls src/classes/*.rb); do
    cp $i tmp/$(basename $i)
done

# Create html-files
for i in $(ls src/html/*.html); do
    sed "s:HOSTNAME:$(hostname):g" $i > tmp/$(basename $i)
done

# Create html-files for hard disks
for i in $HDDS; do
    sed "s:HDD:$i:g" tmp/hdds.html > tmp/hdds-$i.html
    INDEXHDD=$INDEXHDD"<p><a href=\"./hdds-$i.html\"><img border=\"0\" src=\"hdds-$i-day.png\" alt=\"HDD statistics\"></a></p>"
done

# Create html-files for network interfaces
for i in $INTERFACES; do
    sed "s:INTERFACE:$i:g" tmp/network.html > tmp/net-$i.html
    INDEXNET=$INDEXNET"<p><a href=\"./net-$i.html\"><img border=\"0\" src=\"net-$i-day.png\" alt=\"Network statistics\"></a></p>"
done

# Add network and hard disk related lines to index.html
sed "s:NETWORK:$INDEXNET:" tmp/index.html | \
    sed "s:HDD:$INDEXHDD:" > tmp/index.html.tmp
mv tmp/index.html.tmp tmp/index.html

# Remove temporary files
rm tmp/hdds.html
rm tmp/network.html
rm tmp/template.html

# Create rc/init script
sed "s:INSTALLDIR:$PREFIX:" src/rc/sysstat.sh > tmp/sysstat.sh

# Install files
if [ `uname -s` = "FreeBSD" ]; then
    install -d -o root -g wheel -m 755 $PREFIX
    install -d -o root -g wheel -m 755 $PREFIX/bin
    install -d -o root -g wheel -m 755 $PREFIX/etc
    install -d -o root -g wheel -m 755 $PREFIX/db
    install -d -o root -g wheel -m 755 $PREFIX/db/sysstat
    install -d -o root -g wheel -m 755 $PREFIX/lib
    install -d -o root -g wheel -m 755 $PREFIX/lib/sysstat
    install -S -o root -g wheel -m 644 tmp/sysstat.yml $PREFIX/etc/sysstat
    for i in $(ls tmp/S*.rb); do
        install -S -o root -g wheel -m 644 $i $PREFIX/lib/sysstat
    done
    install -S -o root -g wheel -m 755 tmp/sysstat.rb $PREFIX/bin
    install -S -o root -g wheel -m 755 tmp/sysstat.sh $PREFIX/bin
    install -d -o root -g wheel -m 755 $GRAPHDIR
    for i in $(ls tmp/*.html); do
        install -S -o root -g wheel -m 644 $i $GRAPHDIR
    done
elif [ `uname -s` = "Linux" ]; then
    install -d -o root -g root -m 755 $PREFIX
    install -d -o root -g root -m 755 $PREFIX/bin
    install -d -o root -g root -m 755 $PREFIX/etc
    install -d -o root -g root -m 755 $PREFIX/db
    install -d -o root -g root -m 755 $PREFIX/db/sysstat
    install -d -o root -g root -m 755 $PREFIX/lib
    install -d -o root -g root -m 755 $PREFIX/lib/sysstat
    install -o root -g root -m 644 tmp/sysstat.yml $PREFIX/etc/sysstat
    for i in $(ls tmp/S*.rb); do
        install -o root -g root -m 644 $i $PREFIX/lib/sysstat
    done
    install -o root -g root -m 755 tmp/sysstat.rb $PREFIX/bin
    install -o root -g root -m 755 tmp/sysstat.sh $PREFIX/bin
    install -d -o root -g root -m 755 $GRAPHDIR
    for i in $(ls tmp/*.html); do
        install -o root -g root -m 644 $i $GRAPHDIR
    done
fi

# Remove temporary files and directories
rm -rf tmp/

# Message
cat <<EOF

The Sysstat scripts are now installed.
Please check and adjust the configuration. It was installed at:

    $(echo $PREFIX/etc/sysstat/sysstat.yml)

To start the daemon, use the supplied RC/Init script at:

    $(echo $PREFIX/bin/sysstat.sh)

EOF


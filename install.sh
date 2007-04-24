#!/bin/sh

# Copyright (c) 2006,2007 Konstantin Saurbier 
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
PREFIX=		"/usr/local/sysstat"
GRAPHDIR=	"$PREFIX/output"
DBDIR=		"$PREFIX/db"

# Read arguments
while getopts hI:O:P:s:S: ARGS; do
	case $ARGS in
		h)
			# Display help
			echo ""
			echo "System statistics install-script"
			echo ""
			echo "Usage:"
			echo " -h		Display this help screen"
			echo " -I <path>	Install directory"
			echo "			(Default: /usr/local/sysstat)
			echo " -O <path>	Where to write the statistics"
			echo "			(Default: $PREFIX/output)"
			echo " -s		Time in seconds between data gatherings."
			echo " -S		Time in seconds between graph creations."
			exit
			;;
		I)
			PREFIX=		"$OPTARG"
			;;
		O)
			GRAPHDIR=	"$OPTARG"
			;;
		s)	
			STEP=		$(($(($OPTARG / 60)) * 60))
			;;
		S)
			GSTEP=		$(($(($OPTARG / 300)) * 300))
	esac
done

# Prepare variables
PREFIX=		$(echo $PREFIX | sed "s:*/$::")
CONF=		"$PREFIX/etc/sysstat.conf.rb"
DBDIR=		"$PREFIX/db"
GRAPHDIR=	$(echo $GRAPHDIR | sed "s:*/$::")

if [ `uname -s` = "FreeBSD" ]; then
	RAM=	"$(sysctl -n hw.physmem)"
	SWAP=	"$(($(swapinfo -k | tail -1 | awk '{print $2}') * 1024))"
	OS=	"freebsd6"
elif [ `uname -s` = "Linux" ]; then
	RAM=	"$(($(cat /proc/meminfo | grep -w "MemTotal:" | awk '{print $2}') * 1024))
	SWAP=	"$(($(cat /proc/meminfo | grep -w "SwapTotal:" | awk '{print $2}') * 1024))
	OS=	"linux2.6"
fi

HDDS= $(mount | egrep -v "proc|devfs|udev|tmpfs|sysfs|usbfs|devpts|nfs|autofs" | \
		cut -f1 -d" " | cut -f3 -d"/" | tr "\n" " " | sed 's: $::')
INTERFACES= $(ifconfig | egrep "^[a-z].*" | tr -s "[:space:]" | cut -f1 -d" " | \
		tr ":" " " | tr "\n" " " | sed 's: $::')

# Create temporary files and directories
mkdir -p tmp

# Create configuration file
cat src/conf/sysstat.conf | \
	sed "s:OS:$OS:" | \
	sed "s:INSTALLDIR:$PREFIX:" | \
	sed "s:GRAPHDIR:$GRAPHDIR:" | \
	sed "s:DBDIR:$DBDIR:" | \
	sed "s:STEP:$STEP:" | \
	sed "s:GSTEP:$GSTEP:" | \
	sed "s:INTERFACES:$INTERFACES:" | \
	sed "s:HDDS:$HDDS:" | \
	sed "s:RAM:$RAM:" | \
	sed "s:SWAP:$SWAP:" > tmp/sysstat.conf

# Create daemon
sed "s:CONF:$CONF:" src/bin/sysstat.rb > tmp/sysstat.rb

# Create classes
for i in $(ls src/classes/*.rb); do
	cp $i tmp/$(basename $i)
done

# Create html files
for i in $(ls src/html/*.html); do
	sed "s:HOSTNAME:$(hostname -s):g" $i > tmp/$(basename $i)
done

for i in $HDDS; do
	sed "s:HDD:$i:g" tmp/hdds.html > tmp/hdds-$i.html
	INDEXHDD=$INDEXHDD"<p><a href=\"./hdds-$i.html\"><img border=\"0\" src=\"hdds-$i-day.png\" alt=\"HDD statistics\"></a></p>\n"
done

for i in $INTERFACES; do
	sed "s:INTERFACE:$i:g" tmp/network.html > tmp/net-$i.html
	INDEXNET=$INDEXNET"<p><a href=\"./net-$i.html\"><img border=\"0\" src=\"net-$i-day.png\" alt=\"Network statistics\"></a></p>\n"
done

sed "s:NETWORK:$INDEXNET:" tmp/index.html | \
 	sed "s:HDD:$INDEXHDD:" > tmp/index.html.tmp
mv tmp/index.html.tmp tmp/index.html

rm tmp/network.html

# Install files
if [ `uname -s` = "FreeBSD" ]; then
	install -d -o root -g wheel -m 755 $PREFIX
	install -d -o root -g wheel -m 755 $PREFIX/bin
	install -d -o root -g wheel -m 755 $PREFIX/etc
	install -d -o root -g wheel -m 755 $PREFIX/db
	install -d -o root -g wheel -m 755 $PREFIX/lib
	install -S -o root -g wheel -m 644 tmp/sysstat.conf.rb $PREFIX/etc
	for i in $(ls tmp/S*.rb); do
		install -S -o root -g wheel -m 644 $i $PREFIX/lib
	done
	install -S -o root -g wheel -m 755 tmp/sysstat.rb $PREFIX/bin
	install -d -o root -g wheel -m 755 $GRAPHDIR
	for i in $(ls tmp/*.html); do
		install -S -o root -g wheel -m 644 -i $GRAPHDIR
	done
elif [ `uname -s` = "Linux" ]; then
	install -d -o root -g root -m 755 $PREFIX
	install -d -o root -g root -m 755 $PREFIX/bin
	install -d -o root -g root -m 755 $PREFIX/etc
	install -d -o root -g root -m 755 $PREFIX/db
	install -d -o root -g root -m 755 $PREFIX/lib
	install -o root -g root -m 755 tmp/sysstat.rb $PREFIX/bin
	install -o root -g root -m 644 tmp/sysstat.conf.rb $PREFIX/etc
	for i in $(ls tmp/S*.rb); do
		install -o root -g root -m 644 $i $PREFIX/lib
	done
	install -d -o root -g root -m 755 $GRAPHDIR
	for i in $(ls tmp/*.html); do
		install -o root -g root -m 644 -i $GRAPHDIR
	done
fi

# Remove temporary files and directories
rm -rf tmp/

# Message
cat <<EOF

The Sysstat scripts are now installed.
Please start the daemon with the supplied RC/Init script at:

	$(echo $PREFIX/bin/sysstat.sh)

EOF


#!/bin/sh

# Copyright (c) 2006-2008 Konstantin Saurbier <konstantin@saurbier.net>
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


SYSSTAT_RB=BINDIR/sysstat.rb
PID_FILE=/var/run/sysstat.pid

case "$1" in
'start')
    echo "Starting system statistics: sysstat";
    $SYSSTAT_RB --pid-file $PID_FILE &
    ;;

'stop')
    echo "Stopping system statistics: sysstat";
    if [ -f $PID_FILE ]; then
        kill `cat $PID_FILE`
    else
        echo "sysstat not running(?)";
    fi
    ;;

'reload')
    echo "Reloading system statistics: sysstat";
    if [ -f $PID_FILE ]; then
        kill -USR1 `cat $PID_FILE`
    else
        echo "sysstat not running(?)";
    fi
    ;;

'restart')
    echo "Restarting system statistics: sysstat";
    if [ -f $PID_FILE ]; then
        kill `cat $PID_FILE`
        sleep 3
        $SYSSTAT_RB --pid-file $PID_FILE &
    else
        echo "sysstat not running(?)";
    fi
    ;;

'*')
    echo "Sysstat VERSION"
    echo "  COPYRIGHT"
    echo "  http://konstantin.saurbier.net/software/sysstat"
    echo " "
    echo 'Usage: $0 { start | stop | reload | restart }'
    exit 1
    ;;

esac
exit 0

#!/usr/bin/env ruby

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


class Sconnections
  @@config = 0
  @@data = Hash.new 

  def initialize(config)
    @@config = config
    @@data['udp'] = 0
    @@data['tcp'] = 0
    @@rrd = RRDtool.new("#{@@config['dbdir']}/#{@@config['connections_prefix']}.rrd")
  end

  def mkdb
    if(!FileTest.exist?(@@rrd.rrdname))
      @@rrd.create(@@config['step'], Time.now.to_i-1,
        ["DS:tcp:GAUGE:#{@@config['step']+60}:0:U",
         "DS:udp:GAUGE:#{@@config['step']+60}:0:U",
         "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
         "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
         "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
         "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760"])
    end
  end

  def get
    @@data['tcp'] = 0
    @@data['udp'] = 0

    if(@@config['os'] == "freebsd6" || @@config['os'] == "linux2.6")
      @output = %x[netstat -n]
      @output.each do |line|
        if(line =~ /tcp/)
          @@data['tcp'] += 1
        elsif(line =~ /udp/)
          @@data['udp'] += 1
        end
      end
    end
  end

  def write
    @@rrd.update("tcp:udp", ["N:#{@@data['tcp']}:#{@@data['udp']}"])
  end

  def graph(timeframe)
    @time = timeframe
    
    if(@time == "day")
      @start = -86400
      @suffix = "day"
    elsif(@time == "week")
      @start = -604800
      @suffix = "week"
    elsif(@time == "month")
      @start = -2678400
      @suffix = "month"
    elsif(@time == "year")
      @start = -31536000
      @suffix = "year"
    end

    RRDtool.graph(
      ["#{@@config['graphdir']}/#{@@config['connections_prefix']}-#{@suffix}.png",
       "--title", "Network connections",
       "--start", "#{@start}", 
       "--interlace",
       "--imgformat", "PNG",
       "--width=600", "--height=150",
       "--vertical-label", "Connections",
       "--color", "SHADEA#ffffff",
       "--color", "SHADEB#ffffff",
       "--color", "BACK#ffffff",
       "COMMENT:\t\t   Current\t\t  Average\t\t Maximum\\n",
       "DEF:tcp=#{@@rrd.rrdname}:tcp:AVERAGE",
       "LINE1:tcp#ff0000:TCP ",
       "VDEF:tcplast=tcp,LAST", "GPRINT:tcplast: %12.3lf ",
       "VDEF:tcpavg=tcp,AVERAGE", "GPRINT:tcpavg: %12.3lf ",
       "VDEF:tcpmax=tcp,MAXIMUM", "GPRINT:tcpmax: %12.3lf\\n",
       "DEF:udp=#{@@rrd.rrdname}:udp:AVERAGE",
       "LINE1:udp#0000ff:UDP ",
       "VDEF:udplast=udp,LAST", "GPRINT:udplast: %12.3lf ",
       "VDEF:udpavg=udp,AVERAGE", "GPRINT:udpavg: %12.3lf ",
       "VDEF:udpmax=udp,MAXIMUM", "GPRINT:udpmax: %12.3lf"])
  end
end


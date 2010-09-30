#!/usr/bin/env ruby

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
  def initialize(config)
    @config = config

    @data = Hash.new
    @data['udp'] = 0
    @data['tcp'] = 0

    @rrdname = "#{@config['Smain']['dbdir']}/#{@config['Sconnections']['prefix']}.rrd"
  end

  def mkdb
    if(!FileTest.exist?(@rrdname))
      RRD.create(
          @rrdname,
          "--step", "#{@config['Smain']['step']}",
          "--start", "#{Time.now.to_i-1}",
          "DS:tcp:GAUGE:#{@config['Smain']['step']+60}:0:U",
          "DS:udp:GAUGE:#{@config['Smain']['step']+60}:0:U",
          "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
          "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
          "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
          "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760")
    end
  end

  def get
    @data['udp'] = 0
    @data['tcp'] = 0

    output = %x[netstat -n]
    output.each do |line|
      if(line =~ /tcp/)
        @data['tcp'] += 1
      elsif(line =~ /udp/)
        @data['udp'] += 1
      end
    end

    return @data
  end

  def write
    if(RRD.update(@rrdname, "N:#{@data['tcp']}:#{@data['udp']}"))
      return true
    else
      return false
    end
  end

  def graph(timeframe, filename = nil)
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

    unless(filename)
      filename = "#{@config['Smain']['graphdir']}/#{@config['Sconnections']['prefix']}-#{@suffix}.png"
    end

    output = Array.new

    output << RRD.graph(
       filename,
       "--title", "Network connections",
       "--start", "#{@start}",
       "--interlace",
       "--imgformat", "PNG",
       "--width=600", "--height=150",
       "--vertical-label", "Connections",
       "--color", "SHADEA#ffffff",
       "--color", "SHADEB#ffffff",
       "--color", "BACK#ffffff",
       "DEF:tcp=#{@rrdname}:tcp:AVERAGE",
       "CDEF:Ln1=tcp,tcp,UNKN,IF",
       "AREA:tcp#EA644A:TCP",
       "LINE1:Ln1#CC3118",
       "VDEF:tcplast=tcp,LAST", "GPRINT:tcplast: cur\\: %5.0lf ",
       "VDEF:tcpavg=tcp,AVERAGE", "GPRINT:tcpavg: avg\\: %5.0lf ",
       "VDEF:tcpmax=tcp,MAXIMUM", "GPRINT:tcpmax: max\\: %5.0lf\\n",
       "DEF:udp=#{@rrdname}:udp:AVERAGE",
       "CDEF:Ln2=udp,tcp,udp,+,UNKN,IF",
       "AREA:udp#EC9D48:UDP:STACK",
       "LINE1:Ln2#CC7016",
       "VDEF:udplast=udp,LAST", "GPRINT:udplast: cur\\: %5.0lf ",
       "VDEF:udpavg=udp,AVERAGE", "GPRINT:udpavg: avg\\: %5.0lf ",
       "VDEF:udpmax=udp,MAXIMUM", "GPRINT:udpmax: max\\: %5.0lf\\n")

      return output
  end
end


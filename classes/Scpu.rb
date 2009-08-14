#!/usr/bin/env ruby

# Copyright (c) 2006-2009 Konstantin Saurbier <konstantin@saurbier.net>
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


class Scpu
  def initialize(config)
    @config = config

    @data = Hash.new
    @data['idle'] = 0
    @data['system'] = 0
    @data['user'] = 0

    @rrdname = "#{@config["Smain"]['dbdir']}/#{@config['Scpu']['prefix']}.rrd"
  end

  def mkdb
    if(!FileTest.exist?(@rrdname))
      RRD.create(@rrdname,
        "--step", "#{@config["Smain"]['step']}",
        "--start", "#{Time.now.to_i-1}",
        "DS:usr:GAUGE:#{@config["Smain"]['step']+60}:0:U",
        "DS:sys:GAUGE:#{@config["Smain"]['step']+60}:0:U",
        "DS:idl:GAUGE:#{@config["Smain"]['step']+60}:0:U",
        "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
        "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
        "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
        "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760")
    end
  end

  def get
    @data['idle'] = 0
    @data['system'] = 0
    @data['user'] = 0

    sleep 5

    if(@config['Smain']['os'] == "freebsd6")
      output = %x[vmstat -c 4 -w 1 -p proc]
      output.each do |line|
        linea = line.split
        @data['idle'] = linea[16]
        @data['system'] = linea[15]
        @data['user'] = linea[14]
      end
    elsif(@config['Smain']['os'] == "linux2.6")
      output = %x[vmstat]
      outpu.each do |line|
        linea = line.split
        @data['idle'] = linea[14]
        @data['system'] = linea[13]
        @data['user'] = linea[12]
      end
    end
  end

  def write
    RRD.update(@rrdname, "N:#{@data['user']}:#{@data['system']}:#{@data['idle']}")
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
      filename = "#{@config["Smain"]['graphdir']}/#{@config['Scpu']['prefix']}-#{@suffix}.png"
    end

    output = Array.new

    output << RRD.graph(
      filename,
      "--title", "CPU usage",
      "--start", "#{@start}",
      "--interlace",
      "--imgformat", "PNG",
      "--width=600", "--height=150",
      "--vertical-label", "Percent",
      "--color", "SHADEA#ffffff",
      "--color", "SHADEB#ffffff",
      "--color", "BACK#ffffff",
      "--units-exponent", "0",
      "COMMENT:\t   Current\tAverage\t\tMaximum\\n",
      "DEF:usr=#{@rrdname}:usr:AVERAGE",
      "DEF:sys=#{@rrdname}:sys:AVERAGE",
      "DEF:idl=#{@rrdname}:idl:AVERAGE",
      "CDEF:Ln1=usr,idl,sys,+,+", "CDEF:Ln2=usr,sys,+",
      "LINE1:Ln1#24BC14:Idle   ",
      "VDEF:idllast=idl,LAST", "GPRINT:idllast:%3.0lf%%",
      "VDEF:idlavg=idl,AVERAGE" ,"GPRINT:idlavg:\t%3.0lf%%",
      "VDEF:idlmax=idl,MAXIMUM", "GPRINT:idlmax:\t%3.0lf%%\\n",
      "AREA:sys#EC9D48:System ", "LINE1:sys#CC7016",
      "VDEF:syslast=sys,LAST", "GPRINT:syslast:%3.0lf%%",
      "VDEF:sysavg=sys,AVERAGE", "GPRINT:sysavg:\t%3.0lf%%",
      "VDEF:sysmax=sys,MAXIMUM", "GPRINT:sysmax:\t%3.0lf%%\\n",
      "AREA:usr#ECD748:User   :STACK", "LINE1:Ln2#C9B215:",
      "VDEF:usrlast=usr,LAST", "GPRINT:usrlast:%3.0lf%%",
      "VDEF:usravg=usr,AVERAGE", "GPRINT:usravg:\t%3.0lf%%",
      "VDEF:usrmax=usr,MAXIMUM", "GPRINT:usrmax:\t%3.0lf%%\\n")

    return output
  end
end

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


class Scpu
  @@config = 0
  @@data = Hash.new 

  def initialize(config)
    @@config = config
    @@data['idle'] = 0
    @@data['system'] = 0
    @@data['user'] = 0
    @@rrd = RRDtool.new("#{@@config['dbdir']}/#{@@config['cpu_prefix']}.rrd")
  end

  def mkdb
    if(!FileTest.exist?(@@rrd.rrdname))
      @@rrd.create(@@config['step'], Time.now.to_i-1,
        ["DS:usr:GAUGE:#{@@config['step']+60}:0:U",
         "DS:sys:GAUGE:#{@@config['step']+60}:0:U",
         "DS:idl:GAUGE:#{@@config['step']+60}:0:U",
         "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
         "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
         "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
         "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760"])
    end
  end

  def get
    @@data['idle'] = 0
    @@data['system'] = 0
    @@data['user'] = 0

    if(@@config['os'] == "freebsd6")
      @output = %x[vmstat -p proc]
      @output.each do |line|
        linea = line.split
        @@data['idle'] = linea[16]
        @@data['system'] = linea[15]
        @@data['user'] = linea[14]
      end
    elsif(@@config['os'] == "linux2.6")
      @output = %x[vmstat]
      @outpu.each do |line|
        linea = line.split
        @@data['idle'] = linea[14]
        @@data['system'] = linea[13]
        @@data['user'] = linea[12]
      end
    end
  end

  def write
    @@rrd.update("usr:sys:idl",
      ["N:#{@@data['user']}:#{@@data['system']}:#{@@data['idle']}"])
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
      ["#{@@config['graphdir']}/#{@@config['cpu_prefix']}-#{@suffix}.png",
       "--title", "CPU usage",
       "--start", "#{@start}", 
       "--interlace",
       "--imgformat", "PNG",
       "--width=600", "--height=150",
       "--vertical-label", "Percent",
       "--color", "SHADEA#ffffff",
       "--color", "SHADEB#ffffff",
       "--color", "BACK#ffffff",
       "COMMENT:\"\t   Current\t   Average\t    Maximum\\n\"",
       "DEF:usr=#{@@rrd.rrdname}:usr:AVERAGE",
       "DEF:sys=#{@@rrd.rrdname}:sys:AVERAGE",
       "DEF:idl=#{@@rrd.rrdname}:idl:AVERAGE",
       "LINE1:idl#00ff00:\"Idle   \"",
       "VDEF:idllast=idl,LAST", "GPRINT:idllast:\"%3.0lf%%\"",
       "VDEF:idlavg=idl,AVERAGE" ,"GPRINT:idlavg:\"\t%3.0lf%%\"",
       "VDEF:idlmax=idl,MAXIMUM", "GPRINT:idlmax:\"\t%3.0lf%%\\n\"",
       "LINE1:sys#0000ff:\"System \"",
       "VDEF:syslast=sys,LAST", "GPRINT:syslast:\"%3.0lf%%\"",
       "VDEF:sysavg=sys,AVERAGE", "GPRINT:sysavg:\"\t%3.0lf%%\"",
       "VDEF:sysmax=sys,MAXIMUM", "GPRINT:sysmax:\"\t%3.0lf%%\\n\"",
       "LINE1:usr#ff0000:\"User   \"",
       "VDEF:usrlast=usr,LAST", "GPRINT:usrlast:\"%3.0lf%%\"",
       "VDEF:usravg=usr,AVERAGE", "GPRINT:usravg:\"\t%3.0lf%%\"",
       "VDEF:usrmax=usr,MAXIMUM", "GPRINT:usrmax:\"\t%3.0lf%%\""]) 
  end
end

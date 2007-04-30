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


class Sdisk
  @@config = 0
  @@data = Hash.new 
  @@rrd = Hash.new

  def initialize(config)
    @@config = config
    @@config['hdds'].split().each do |hdd|
      @@rrd[hdd] = RRDtool.new("#{@@config['dbdir']}/#{@@config['hdds_prefix']}-#{hdd}.rrd")
      @@data[hdd] = Hash.new
      @@data[hdd]['size'] = 0
      @@data[hdd]['used'] = 0
    end
  end

  def mkdb
    @@config['hdds'].split().each do |hdd|
      if(!FileTest.exist?(@@rrd[hdd].rrdname))
        @@rrd[hdd].create(@@config['step'], Time.now.to_i-1,
          ["DS:size:COUNTER:#{@@config['step']+60}:0:U",
           "DS:used:COUNTER:#{@@config['step']+60}:0:U",
           "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
           "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
           "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
           "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760"])
      end
    end
  end

  def get
    @@config['hdds'].split().each do |hdd|
      @@data[hdd]['size'] = %x[df -k | grep ad0s1e | tr -s "[:space:]" | cut -f2 -d" "]
      @@data[hdd]['used'] = %x[df -k | grep ad0s1e | tr -s "[:space:]" | cut -f3 -d" "]
      
      @output = %x[df -k]
      @output.each do |line|
        regex = Regexp.new("^/dev/#{hdd}")
        if(line =~ regex)
          @@data[hdd]['size'] = line.split()[2]
          @@data[hdd]['used'] = line.split()[3]
        end
      end
    end
  end

  def write
    @@config['hdds'].split().each do |hdd|
      @@rrd[hdd].update("size:used",
        ["N:#{@@data[hdd]['size']}:#{@@data[hdd]['used']}"])
    end
  end

  def graph(time)
    if(time == "day")
      @start = -86400
      @suffix = "day"
    elsif(time == "week")
      @start = -604800
      @suffix = "week"
    elsif(time == "month")
      @start = -2678400
      @suffix = "month"
    elsif(time == "year")
      @start = -31536000
      @suffix = "year"
    end

    @@config['hdds'].split().each do |hdd|
      RRDtool.graph(
        ["#{@@config['graphdir']}/#{@@config['hdds_prefix']}-#{hdd}-#{@suffix}.png",
         "--title", "Usage statistics for /dev/#{hdd}",
         "--start", "#{@start}", 
         "--interlace",
         "--imgformat", "PNG",
         "--width=600", "--height=150",
         "--vertical-label", "Bytes",
         "--color", "SHADEA#ffffff",
         "--color", "SHADEB#ffffff",
         "--color", "BACK#ffffff",
         "DEF:ksize=#{@@rrd[hdd].rrdname}:size:AVERAGE",
         "DEF:kused=#{@@rrd[hdd].rrdname}:used:AVERAGE",
         "COMMENT:\t\t\t   Current\t\t  Average\t\t Maximum\\n",
         "CDEF:size=ksize,1024,*",    "LINE1:size#ff0000:size",
         "VDEF:sizelast=size,LAST",   "GPRINT:sizelast: %12.3lf ",
         "VDEF:sizeavg=size,AVERAGE", "GPRINT:sizeavg: %12.3lf ",
         "VDEF:sizemax=size,MAXIMUM", "GPRINT:sizemax: %12.3lf\\n",
         "CDEF:used=kused,1024,*",    "AREA:used#00ff00:usage",
         "VDEF:usedlast=used,LAST",   "GPRINT:usedlast: %12.3lf ",
         "VDEF:usedavg=used,AVERAGE", "GPRINT:usedavg: %12.3lf ",
         "VDEF:usedmax=used,MAXIMUM", "GPRINT:usedmax: %12.3lf\\n",
         "CDEF:free=size,used,-",     "LINE1:free#0000ff:free",
         "VDEF:freelast=free,LAST",   "GPRINT:freelast: %12.3lf ",
         "VDEF:freeavg=free,AVERAGE", "GPRINT:freeavg: %12.3lf ",
         "VDEF:freemax=free,MAXIMUM", "GPRINT:freemax: %12.3lf"])
    end
  end
end

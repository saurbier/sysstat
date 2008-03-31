#!/usr/bin/env ruby

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


class Sdisk
  @config = 0
  @data = Hash.new 
  @rrd = Hash.new

  def initialize(config)
    @config = config
    @config['Sdisk']['devices'].each do |hdd|
      @rrd[hdd] = RRDtool.new("#{@config['Smain']['dbdir']}/#{@config['Sdisk']['prefix']}-#{hdd}.rrd")
      @data[hdd] = Hash.new
      @data[hdd]['size'] = 0
      @data[hdd]['used'] = 0
    end
  end

  def mkdb
    @config['Sdisk']['devices'].each do |hdd|
      if(!FileTest.exist?(@rrd[hdd].rrdname))
        @rrd[hdd].create(@config['Smain']['step'], Time.now.to_i-1,
          ["DS:size:GAUGE:#{@config['Smain']['step']+60}:0:U",
           "DS:used:GAUGE:#{@config['Smain']['step']+60}:0:U",
           "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
           "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
           "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
           "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760"])
      end
    end
  end

  def get
    @config['Sdisk']['devices'].each do |hdd|      
      output = %x[df -m]
      output.each do |line|
        regex = Regexp.new("^/dev/#{hdd}")
        if(line =~ regex)
          @data[hdd]['size'] = line.split()[1]
          @data[hdd]['used'] = line.split()[2]
        end
      end
    end
  end

  def write
    @config['Sdisk']['devices'].each do |hdd|
      @rrd[hdd].update("size:used",
        ["N:#{@data[hdd]['size']}:#{@data[hdd]['used']}"])
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

    @config['Sdisk']['devices'].each do |hdd|
      RRDtool.graph(
        ["#{@config['Smain']['graphdir']}/#{@config['Sdisk']['prefix']}-#{hdd}-#{@suffix}.png",
         "--title", "Usage statistics for /dev/#{hdd}",
         "--start", "#{@start}", 
         "--interlace",
         "--imgformat", "PNG",
         "--width=600", "--height=150",
         "--vertical-label", "MBytes",
         "--color", "SHADEA#ffffff",
         "--color", "SHADEB#ffffff",
         "--color", "BACK#ffffff",
         "--base", "1024",
         "DEF:sizek=#{@rrd[hdd].rrdname}:size:AVERAGE",
         "DEF:usedk=#{@rrd[hdd].rrdname}:used:AVERAGE",
         "CDEF:size=sizek,1024,*", "CDEF:used=usedk,1024,*",
         "CDEF:free=size,used,-",
         "COMMENT:\t\t\t Current\t\t  Average\t\t   Maximum\\n",
         "AREA:used#0000ff:usage",
         "VDEF:usedlast=used,LAST",   "GPRINT:usedlast: %12.3lf %sB",
         "VDEF:usedavg=used,AVERAGE", "GPRINT:usedavg: %12.3lf %sB",
         "VDEF:usedmax=used,MAXIMUM", "GPRINT:usedmax: %12.3lf %sB\\n",
         "AREA:free#55dd55:free:STACK",
         "VDEF:freelast=free,LAST",   "GPRINT:freelast:  %12.3lf %sB",
         "VDEF:freeavg=free,AVERAGE", "GPRINT:freeavg: %12.3lf %sB",
         "VDEF:freemax=free,MAXIMUM", "GPRINT:freemax: %12.3lf %sB"])
    end
  end
end

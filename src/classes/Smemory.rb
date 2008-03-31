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


class Smemory
  @config = 0
  @data = Hash.new 

  def initialize(config)
    @config = config
    @data['fram'] = 0
    @data['fswap'] = 0
    @rrd = RRDtool.new("#{@config['Smain']['dbdir']}/#{@config['Smemory']['prefix']}.rrd")
  end

  def mkdb
    if(!FileTest.exist?(@rrd.rrdname))
      @rrd.create(@config['Smain']['step'], Time.now.to_i-1,
        ["DS:ram:GAUGE:#{@config['Smain']['step']+60}:0:U",
         "DS:swap:GAUGE:#{@config['Smain']['step']+60}:0:U", 
         "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
         "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760"])
    end
  end

  def get
    if(@config['os'] == "freebsd6")
      output = %x[vmstat]
      output.each do |line|
        @data['fram'] = line.split()[4].to_i
      end

      output = %x[swapinfo -k]
      output.each do |line|
        @data['fswap'] = line.split()[3].to_i
      end
    elsif(@config['os'] == "linux2.6")
      output = File.new("/proc/meminfo", "r") 
      output.each do |line|
        if(line =~ /MemFree:/)
          @data['fram'] = line.split()[1].to_i
        elsif(line =~ /SwapFree:/)
          @data['fswap'] = line.split()[1].to_i
        end
      end
      output.close
    end
  end

  def write
    @rrd.update("ram:swap", ["N:#{@data['fram']}:#{@data['fswap']}"])
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
      ["#{@config['Smain']['graphdir']}/#{@config['Smemory']['prefix']}-#{@suffix}.png",
       "--title", "RAM and Swap usage",
       "--start", "#{@start}", 
       "--interlace",
       "--imgformat", "PNG",
       "--width=600", "--height=150",
       "--vertical-label", "Bytes",
       "--color", "SHADEA#ffffff",
       "--color", "SHADEB#ffffff",
       "--color", "BACK#ffffff",
       "--base", "1024",
       "DEF:framk=#{@rrd.rrdname}:ram:AVERAGE",
       "DEF:fswapk=#{@rrd.rrdname}:swap:AVERAGE",
       "CDEF:uramk=#{@config['mem_ramtotal']},framk,-",
       "CDEF:uswapk=#{@config['mem_swaptotal']},fswapk,-",
       "CDEF:fram=framk,1024,*", "CDEF:fswap=fswapk,1024,*",
       "CDEF:uram=uramk,1024,*", "CDEF:uswap=uswapk,1024,*",
       "VDEF:uramlast=uram,LAST", "VDEF:framlast=fram,LAST",
       "VDEF:uswaplast=uswap,LAST", "VDEF:fswaplast=fswap,LAST",
       "AREA:uswap#ff0000:used SWAP\\:",
       "GPRINT:uswaplast: %4.3lf %sB",
       "LINE2:fswap#000000:\tfree SWAP\\:",
       "GPRINT:fswaplast: %4.3lf %sB\\n",
       "AREA:uram#0000ff:used RAM\\:",
       "GPRINT:uramlast:  %4.3lf %sB",
       "AREA:fram#55dd55:\tfree RAM\\::STACK",
       "GPRINT:framlast:  %4.3lf %sB"])
  end
end


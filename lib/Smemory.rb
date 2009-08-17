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
  def initialize(config)
    @config = config

    @data = Hash.new
    @data['fram'] = 0
    @data['fswap'] = 0

    @rrdname = "#{@config['Smain']['dbdir']}/#{@config['Smemory']['prefix']}.rrd"
  end

  def mkdb
    if(!FileTest.exist?(@rrdname))
      RRD.create(
        @rrdname,
        "--step", "#{@config['Smain']['step']}",
        "--start", "#{Time.now.to_i-1}",
#        "DS:kram:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "DS:uram:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "DS:fram:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "DS:swap:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
        "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760")
    end
  end

  def get
    if(@config['Smain']['os'] == "freebsd6")
      # Ram
      output = %x[vmstat]
      output.each do |line|
        linea = line.split()
        @data['uram'] = linea[3].to_i
        @data['fram'] = linea[4].to_i
        linea = nil
      end

      # Kernel size
#      output = %x[kldstat]
#      output.each do |line|
#        @data['kram'] += line.split()[3].hex/1024
#      end

      # Kernel memory
#      output = %x[vmstat -m]
#      output.each do |line|
#        @data['kram'] += line.split()[2].to_i
#      end

      # Swap
      output = %x[swapinfo -k]
      output.each do |line|
        @data['fswap'] = line.split()[3].to_i
      end
      output = nil
    elsif(@config['Smain']['os'] == "linux2.6")
      output = %x[free -k].split("\n")
      @data['uram'] = output[2].split()[2]
      @data['fram'] = output[1].split()[3]
#      @data['kram'] = output[1].split()[6]
      @data['fswap'] = output[3].split()[3]
    end
  end

  def write
#    RRD.update(@rrdname, "N:#{@data['kram']}:#{@data['uram']}:#{@data['fram']}:#{@data['fswap']}")
    RRD.update(@rrdname, "N:#{@data['uram']}:#{@data['fram']}:#{@data['fswap']}")
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
      filename = "#{@config['Smain']['graphdir']}/#{@config['Smemory']['prefix']}-#{@suffix}.png"
    end

    output = Array.new

    output << RRD.graph(
      filename,
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
      "DEF:framk=#{@rrdname}:ram:AVERAGE",
      "DEF:fswapk=#{@rrdname}:swap:AVERAGE",
      "CDEF:uramk=#{@config['Smemory']['ramtotal']},framk,-",
      "CDEF:uswapk=#{@config['Smemory']['swaptotal']},fswapk,-",
      "CDEF:fram=framk,1024,*", "CDEF:fswap=fswapk,1024,*",
      "CDEF:uram=uramk,1024,*", "CDEF:uswap=uswapk,1024,*",
      "VDEF:uramlast=uram,LAST", "VDEF:framlast=fram,LAST",
      "VDEF:uswaplast=uswap,LAST", "VDEF:fswaplast=fswap,LAST",
      "LINE2:uswap#ff0000:used SWAP\\:",
      "GPRINT:uswaplast: %4.3lf %sB",
      "LINE2:fswap#0000ff:\tfree SWAP\\:",
      "GPRINT:fswaplast: %4.3lf %sB\\n",
      "LINE2:uram#ff9900:used RAM\\:",
      "GPRINT:uramlast:  %4.3lf %sB",
      "LINE2:fram#55dd55:\tfree RAM\\:",
      "GPRINT:framlast:  %4.3lf %sB\\n")

    return output
  end
end


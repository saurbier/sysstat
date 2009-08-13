#!/usr/bin/env ruby

# Copyright (c) 2009 Konstantin Saurbier <konstantin@saurbier.net>
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


class Susers
  def initialize(config)
    @config = config

    @data = Hash.new
    @data['users'] = 0

    @rrdname = "#{@config['Smain']['dbdir']}/#{@config['Susers']['prefix']}.rrd"
  end

  def mkdb
    if(!FileTest.exist?(@rrdname))
      RRD.create(
        @rrdname,
        "--step", "#{@config['Smain']['step']}",
        "--start", "#{Time.now.to_i-1}",
        "DS:users:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
        "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
        "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
        "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760")
    end
  end

  def get
    @data['users'] = 0
    @data['users'] = %x[uptime].split(",")[2].to_i
  end

  def write
    RRD.update(@rrdname, "N:#{@data['users']}")
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
      filename = "#{@config['Smain']['graphdir']}/#{@config['Susers']['prefix']}-#{@suffix}.png"
    end

    output = Array.new

    output << RRD.graph(
      filename,
      "--title", "Number of users",
      "--start", "#{@start}",
      "--interlace",
      "--imgformat", "PNG",
      "--width=600", "--height=150",
      "--vertical-label", "users",
      "--color", "SHADEA#ffffff",
      "--color", "SHADEB#ffffff",
      "--color", "BACK#ffffff",
      "--units-exponent", "0",
      "DEF:users=#{@rrdname}:users:AVERAGE",
      "AREA:users#EA644A:User count",
      "LINE1:users#CC3118",
      "VDEF:auswertung1=users,AVERAGE",
      "GPRINT:auswertung1:average\\: %lg",
      "DEF:maxaus=#{@rrdname}:users:MAX",
      "VDEF:maxaus1=maxaus,MAXIMUM",
      "GPRINT:maxaus1:maximum\\: %lg\\n")

    return output
  end
end

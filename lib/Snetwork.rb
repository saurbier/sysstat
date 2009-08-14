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


class Snetwork
  def initialize(config)
    @config = config

    @data = Hash.new
    @rrdname = Hash.new

    @config['Snetwork']['interfaces'].each do |interface|
      @rrdname[interface] = "#{@config['Smain']['dbdir']}/#{@config['Snetwork']['prefix']}-#{interface}.rrd"
      @data[interface] = Hash.new
      @data[interface]['in'] = 0
      @data[interface]['out'] = 0
      @data[interface]['ierr'] = 0
      @data[interface]['oerr'] = 0
    end
  end

  def mkdb
    @config['Snetwork']['interfaces'].each do |interface|
      if(!FileTest.exist?(@rrdname[interface]))
        RRD.create(
          @rrdname[interface],
          "--step", "#{@config['Smain']['step']}",
          "--start", "#{Time.now.to_i-1}",
          "DS:in:COUNTER:#{@config['Smain']['step']+60}:0:U",
          "DS:out:COUNTER:#{@config['Smain']['step']+60}:0:U",
          "DS:ierr:COUNTER:#{@config['Smain']['step']+60}:0:U",
          "DS:oerr:COUNTER:#{@config['Smain']['step']+60}:0:U",
          "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
          "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
          "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
          "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760")
      end
    end
  end

  def get
    @config['Snetwork']['interfaces'].each do |interface|
      if(@config['Smain']['os'] == "freebsd6")
        output = %x[netstat -ib]
        output.each do |line|
          regex = Regexp.new(interface)
          if(line =~ regex and line =~ /Link/ and interface =~ /lo/ and interface =~ /tun/)
            @data[interface]['in'] = line.split()[5]
            @data[interface]['out'] = line.split()[8]
            @data[interface]['ierr'] = line.split()[4]
            @data[interface]['oerr'] = line.split()[7]
          elsif(line =~ regex and line =~ /Link/)
            @data[interface]['in'] = line.split()[6]
            @data[interface]['out'] = line.split()[9]
            @data[interface]['ierr'] = line.split()[5]
            @data[interface]['oerr'] = line.split()[8]
          end
        end
      elsif(@config['Smain']['os'] == "linux2.6")
        output = %x[ifconfig #{interface}]
        output.each do |line|
          if(line =~ /bytes/)
            linea = line.split()
            @data[interface]['in'] = linea[1].split(":")[1]
            @data[interface]['out'] = linea[8].split(":")[1]
          elsif(line =~ /RX packets/)
            @data[interface]['ierr'] = line.split()[2].split(":")[1]
          elsif(line =~ /TX packets/)
            @data[interface]['oerr'] = line.split()[2].split(":")[1]
          end
        end
      end
    end
  end

  def write
    @config['Snetwork']['interfaces'].each do |interface|
      RRD.update(
        @rrdname[interface],
        "N:#{@data[interface]['in']}:#{@data[interface]['out']}:#{@data[interface]['ierr']}:#{@data[interface]['oerr']}")
    end
  end

  def graph(time, filename = nil)
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

    output = Array.new

    @config['Snetwork']['interfaces'].each do |iface|
      unless(filename == "-")
        filename = "#{@config['Smain']['graphdir']}/#{@config['Snetwork']['prefix']}-#{iface}-#{@suffix}.png"
      end
      
      output << RRD.graph(
        filename,
        "--title", "Network Interface #{iface}",
        "--start", "#{@start}",
        "--interlace",
        "--imgformat", "PNG",
        "--width=600", "--height=150",
        "--vertical-label", "Bits/s",
        "--color", "SHADEA#ffffff",
        "--color", "SHADEB#ffffff",
        "--color", "BACK#ffffff",
        "COMMENT:\t\t   Current\t   Average\t  Maximum\t  Datenvolumen\\n",
        "DEF:r=#{@rrdname[iface]}:in:AVERAGE",
        "CDEF:rx=r,8,*",
        "AREA:rx#EA644A:Inbound", "LINE1:rx#CC3118",
        "VDEF:rxlast=rx,LAST", "GPRINT:rxlast: %12.3lf %s",
        "VDEF:rxave=rx,AVERAGE", "GPRINT:rxave:%12.3lf %s",
        "VDEF:rxmax=rx,MAXIMUM", "GPRINT:rxmax:%12.3lf %s",
        "VDEF:rxtotal=r,TOTAL", "GPRINT:rxtotal:%12.1lf %sb\\n",
        "DEF:rerr=#{@rrdname[iface]}:ierr:AVERAGE",
        "CDEF:rxerr=rerr,8,*",
        "LINE1:rxerr#dd0000:Errors in",
        "VDEF:rxerrlast=rxerr,LAST", "GPRINT:rxerrlast: %12.3lf %s",
        "VDEF:rxerrave=rxerr,AVERAGE", "GPRINT:rxerrave:%12.3lf %s",
        "VDEF:rxerrmax=rxerr,MAXIMUM", "GPRINT:rxerrmax:%12.3lf %s",
        "VDEF:rxerrtotal=rerr,TOTAL", "GPRINT:rxerrtotal:%12.1lf %sb\\n",
        "DEF:t=#{@rrdname[iface]}:out:AVERAGE",
        "CDEF:txa=t,-8,*", "CDEF:tx=t,8,*",
        "AREA:txa#EC9D48:Outbound", "LINE1:txa#CC7016",
        "VDEF:txlast=tx,LAST", "GPRINT:txlast:%12.3lf %s",
        "VDEF:txave=tx,AVERAGE", "GPRINT:txave:%12.3lf %s",
        "VDEF:txmax=tx,MAXIMUM", "GPRINT:txmax:%12.3lf %s",
        "VDEF:txtotal=t,TOTAL", "GPRINT:txtotal:%12.1lf %sb\\n",
        "DEF:terr=#{@rrdname[iface]}:oerr:AVERAGE",
        "CDEF:txerra=terr,-8,*", "CDEF:txerr=terr,8,*",
        "LINE1:txerra#dd0000:Errors out",
        "VDEF:txerrlast=txerr,LAST", "GPRINT:txerrlast:%12.3lf %s",
        "VDEF:txerrave=txerr,AVERAGE", "GPRINT:txerrave:%12.3lf %s",
        "VDEF:txerrmax=txerr,MAXIMUM", "GPRINT:txerrmax:%12.3lf %s",
        "VDEF:txerrtotal=terr,TOTAL", "GPRINT:txerrtotal:%12.1lf %sb\\n")
    end

    return output
  end
end


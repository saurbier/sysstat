#!/usr/bin/env ruby

# Copyright (c) 2008 Konstantin Saurbier <konstantin@saurbier.net>
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


class Spostfix
  def initialize(config)
    @config = config
    @data = Hash.new
    @rrdname = Hash.new

    @data['active'] = 0
    @data['deferred'] = 0
    @data['incoming'] = 0
    @data['maildrop'] = 0
    @data['corrupt'] = 0
    @data['hold'] = 0
    
    @rrdname['postfix_queue'] = "#{@config['Smain']['dbdir']}/postfix-queue.rrd"
  end

  def mkdb
    if(!FileTest.exist?(@rrdname['postfix_queue']))
      RRD.create(
        @rrdname['postfix_queue'],
        "--step", "#{@config['Smain']['step']}",
        "--start", "#{Time.now.to_i-1}",
        "DS:active:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "DS:deferred:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "DS:hold:GAUGE:#{@config['Smain']['step']+60}:0:U",
        "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
        "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
        "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
        "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760")
    end
  end

  def get
    # Queue
    @data['active'] = %x[find #{@config['postfix_spooldir']}/active -type f | wc -l | tr -d " " | tr -d "\n"].to_i
    @data['active'] += %x[find #{@config['postfix_spooldir']}/incoming -type f | wc -l | tr -d " " | tr -d "\n"].to_i
    @data['active'] += %x[find #{@config['postfix_spooldir']}/maildrop -type f | wc -l | tr -d " " | tr -d "\n"].to_i
    @data['deferred'] = %x[find #{@config['postfix_spooldir']}/deferred -type f | wc -l | tr -d " " | tr -d "\n"].to_i
    @data['hold'] = %x[find #{@config['postfix_spooldir']}/hold -type f | wc -l | tr -d " " | tr -d "\n"].to_i
    @data['hold'] += %x[find #{@config['postfix_spooldir']}/corrupt -type f | wc -l | tr -d " " | tr -d "\n"].to_i
  end

  def write
    RDD.update(
      @rrdname['postfix_queue'],
      "N:#{@data['active']}:#{@data['deferred']}:#{@data['hold']}")
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

    RRD.graph(
      "#{@config['Smain']['graphdir']}/postfix-queue-#{@suffix}.png",
      "--title", "Network Interface #{interface}",
      "--start", "#{@start}", 
      "--interlace",
      "--imgformat", "PNG",
      "--width=600", "--height=150",
      "--vertical-label", "queuefiles",
      "--color", "SHADEA#ffffff",
      "--color", "SHADEB#ffffff",
      "--color", "BACK#ffffff",
      "COMMENT:\t\t\t   Current\t\t  Average\t\t Maximum\\n",
      "DEF:active=#{@rrdname['postfix_queue']}:active:AVERAGE",
      "LINE2:active#24BC14:Active+Incoming+Maildrop ",
      "VDEF:actlast=active,LAST", "GPRINT:actlast:%12.3lf",
      "VDEF:actmax=active,MAXIMUM", "GPRINT:actmax:%12.3lf",
      "VDEF:actavg=active,AVERAGE", "GPRINT:actavg:%12.3lf\\n",
      "DEF:deferred=#{@rrdname['postfix_queue']}:deferred:AVERAGE",
      "LINE2:deferred#C9B215:Deferred ",
      "VDEF:deflast=deferred,LAST", "GPRINT:deflast: %12.3lf %s",
      "VDEF:defmax=deferred,MAXIMUM", "GPRINT:defmax: %12.3lf %s",
      "VDEF:defavg=deferred,AVERAGE", "GPRINT:defavg: %12.3lf %s\\n",
      "DEF:incoming=#{@rrdname['postfix_queue']}:incoming:AVERAGE",
      "LINE2:hold#CC3118:Hold+Corrupt ",
      "VDEF:holdlast=hold,LAST", "GPRINT:holdlast: %12.3lf %s",
      "VDEF:holdmax=hold,MAXIMUM", "GPRINT:holdmax: %12.3lf %s",
      "VDEF:holdavg=hold,AVERAGE", "GPRINT:holdavg: %12.3lf %s\\n")
    end
  end
end


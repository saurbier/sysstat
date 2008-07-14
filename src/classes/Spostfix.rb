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
         "DS:incoming:GAUGE:#{@config['Smain']['step']+60}:0:U",
         "DS:maildrop:GAUGE:#{@config['Smain']['step']+60}:0:U",
         "DS:corrupt:GAUGE:#{@config['Smain']['step']+60}:0:U",
         "DS:hold:GAUGE:#{@config['Smain']['step']+60}:0:U",
         "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
         "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760",
         "RRA:MAX:0.5:1:2160", "RRA:MAX:0.5:5:2016",
         "RRA:MAX:0.5:15:2880", "RRA:MAX:0.5:60:8760"])
    end
  end

  def get
    # Queue
    @data['active'] = %x[find #{@config['postfix_spooldir']}/active -type f | wc -l]
    @data['deferred'] = %x[find #{@config['postfix_spooldir']}/deferred -type f | wc -l]
    @data['incoming'] = %x[find #{@config['postfix_spooldir']}/incoming -type f | wc -l]
    @data['maildrop'] = %x[find #{@config['postfix_spooldir']}/maildrop -type f | wc -l]
    @data['corrupt'] = %x[find #{@config['postfix_spooldir']}/corrupt -type f | wc -l]
    @data['hold'] = %x[find #{@config['postfix_spooldir']}/hold -type f | wc -l]
  end

  def write
    RDD.update(
      @rrdname['postfix_queue'],
      "N:#{@data['active']}:#{@data['deferred']}:#{@data['incoming']}:#{@data['maildrop']}:#{@data['corrupt']}:#{@data['hold']}")
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
      "DEF:r=#{@rrdname['postfix_queue']}:active:AVERAGE",
      "LINE2:active#00ff00:Active ",
      "GPRINT:active,LAST: %12,3lf %s",
      "GPRINT:active,MAX: %12,3lf %s",
      "GPRINT:active,AVERAGE: %12,3lf %s\\n",
      "DEF:r=#{@rrdname['postfix_queue']}:deferred:AVERAGE",
      "LINE2:deferred#00ff00:Deferred ",
      "GPRINT:deferred,LAST: %12,3lf %s",
      "GPRINT:deferred,MAX: %12,3lf %s",
      "GPRINT:deferred,AVERAGE: %12,3lf %s\\n",
      "DEF:r=#{@rrdname['postfix_queue']}:incoming:AVERAGE",
      "LINE2:incoming#00ff00:Incoming ",
      "GPRINT:incoming,LAST: %12,3lf %s",
      "GPRINT:incoming,MAX: %12,3lf %s",
      "GPRINT:incoming,AVERAGE: %12,3lf %s\\n",
      "DEF:r=#{@rrdname['postfix_queue']}::AVERAGE",
      "LINE2:maildrop#00ff00:Maildrop ",
      "GPRINT:maildrop,LAST: %12,3lf %s",
      "GPRINT:maildrop,MAX: %12,3lf %s",
      "GPRINT:maildrop,AVERAGE: %12,3lf %s\\n",
      "DEF:r=#{@rrdname['postfix_queue']}::AVERAGE",
      "LINE2:corrupt#00ff00:Corrupt ",
      "GPRINT:corrupt,LAST: %12,3lf %s",
      "GPRINT:corrupt,MAX: %12,3lf %s",
      "GPRINT:corrupt,AVERAGE: %12,3lf %s\\n",
      "DEF:r=#{@rrdname['postfix_queue']}::AVERAGE",
      "LINE2:hold#00ff00:Held ",
      "GPRINT:hold,LAST: %12,3lf %s",
      "GPRINT:hold,MAX: %12,3lf %s",
      "GPRINT:hold,AVERAGE: %12,3lf %s\\n")
    end
  end
end


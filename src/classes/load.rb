#!/usr/local/bin/ruby

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


class connections
	@@config = 0
	@@data = Hash.new 

	def initialize(config)
		@@config = config
		@@data['1min'] = 0
		@@data['5min'] = 0
		@@data['15min'] = 0
	end

	def mkdb
		%x[#{@@config['rrdtool']} create \
			#{@@config['dbdir']}/@@config['load_prefix']}.rrd \
			--step #{@@config['step']} DS:tcp:GAUGE:120:0:U \
			DS:load1:GAUGE:120:0:U \
			DS:load5:GAUGE:120:0:U \
			DS:load15:GAUGE:120:0:U \
			RRA:AVERAGE:0.5:1:2160 RRA:AVERAGE:0.5:5:2016 \
			RRA:AVERAGE:0.5:15:2880 RRA:AVERAGE:0.5:60:8760 \
			RRA:MAX:0.5:1:2160 RRA:MAX:0.5:5:2016 \
			RRA:MAX:0.5:15:2880 RRA:MAX:0.5:60:8760]
	end

	def get
		if(@@config['os'] == "freebsd6")
			@output = %x[sysctl vm.loadavg]
			@output.each do |line|
				linea = line.split
				@@data['1min'] = linea[2]
				@@data['5min'] = linea[3]
				@@data['15min'] = linea[4]
			end

		elsif(@@config['os'] == "linux2.6")
			@output = File.new("/proc/loadavg", "r")
			@output.each_line do |line|
				linea = line.split
				@@data['1min'] = linea[0]
				@@data['5min'] = linea[1]
				@@data['15min'] = linea[2]
			end
			@output.close
		end
	end

	def write
		%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/@@config['load_prefix']}.rrd N:#{@@data['1min']}:#{@@data['5min']}:#{@@data['15min']}]
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

		%[#{@@config['rrdtool']} graph \
			#{@@config['graphdir']}/#{@@config['load_prefix']}-#{@suffix}.rrd -i \
			--start #{@start} -a PNG -t "Load Average" \
			--vertical-label "Load" -w 600 -h 150 \
			--color SHADEA#ffffff --color SHADEB#ffffff \
			--color BACK#ffffff \
			COMMENT:"\t\t\t   Current\t     Average\t  Maximum\n" \
			DEF:load1=$DBDIR$LOAD_PREFIX.rrd:load1:AVERAGE \
			DEF:load5=$DBDIR$LOAD_PREFIX.rrd:load5:AVERAGE \
			DEF:load15=$DBDIR$LOAD_PREFIX.rrd:load15:AVERAGE \
			AREA:load1#ff0000:"1 minute  " LINE1:load1#ff0000:"" \
			VDEF:load1l=load1,LAST GPRINT:load1l:"%12.2lf" \
			VDEF:load1avg=load1,AVERAGE GPRINT:load1avg:"%12.2lf" \
			VDEF:load1max=load1,MAXIMUM \
			GPRINT:load1max:"%12.2lf\n" \
			AREA:load5#ff9900:"5 minutes " LINE1:load5#ff9900:"" \
			VDEF:load5l=load5,LAST GPRINT:load5l:"%12.2lf" \
			VDEF:load5avg=load5,AVERAGE GPRINT:load5avg:"%12.2lf" \
			VDEF:load5max=load5,MAXIMUM \
			GPRINT:load5max:"%12.2lf\n" \
			AREA:load15#ffff00:"15 minutes" \
			VDEF:load15l=load15,LAST GPRINT:load15l:"%12.2lf" \
			VDEF:load15avg=load15,AVERAGE \
			GPRINT:load15avg:"%12.2lf" \
			VDEF:load15max=load15,MAXIMUM \
			GPRINT:load15max:"%12.2lf\n"]
	end
end


#!RUBYPATH

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
		@@data['fram'] = 0
		@@data['fswap'] = 0
	end

	def mkdb
		%x[#{@@config['rrdtool']} create \
			#{@@config['dbdir']}/@@config['memory_prefix']}.rrd \
			--step #{@@config['step']} \
			DS:ram:GAUGE:120:0:U \
			DS:swap:GAUGE:120:0:U \
			RRA:AVERAGE:0.5:1:2160 RRA:AVERAGE:0.5:5:2016 \
			RRA:AVERAGE:0.5:15:2880 RRA:AVERAGE:0.5:60:8760]
	end

	def get
		if(@@config['os'] == "freebsd6")
			@output = %x[vmstat]
			@output.each do |line|
				linea = line.split()
				@@data['fram'] = linea[4]
			end
		elsif(@@config['os'] == "linux2.6")
			@output = File.new("/proc/meminfo", "r") 
			@output.each do |line|
				if(line =~ /MemFree:/)
					@@data['fram'] = line.split()[1]
				elsif(line =~ /SwapFree:/)
					@@data['fswap'] = line.split()[1]
				end
			end
			@output.close
		end
	end

	def write
		%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/@@config['_prefix']}.rrd N:#{@@data['value']}]
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
			#{@@config['graphdir']}/#{@@config['memory_prefix']}-#{@suffix}.rrd -i \
			--start #{@start} -a PNG -t "RAM and Swap" \
			--vertical-label "Bytes" -w 600 -h 150 \
			--color SHADEA#ffffff --color SHADEB#ffffff \
			--color BACK#ffffff \
			DEF:ramk=$DBDIR$RAM_PREFIX.rrd:ram:AVERAGE \
			DEF:swapk=$DBDIR$RAM_PREFIX.rrd:swap:AVERAGE \
			CDEF:ram=ramk,1024,* CDEF:swap=swapk,1024,* \
			CDEF:bram=$RAM_TOTAL,ram,- \
			CDEF:bswapk=$RAM_SWAPTOTAL,swapk,- \
			CDEF:bswap=bswapk,1024,* \
			VDEF:bramlast=bram,LAST VDEF:ramlast=ram,LAST \
			VDEF:bswaplast=bswap,LAST VDEF:swaplast=swap,LAST \
			AREA:bram#99ffff:"used RAM\: " \
			GPRINT:bramlast:"%4.3lf %sB " \
			LINE1:ram#ff0000:"free RAM\: " \
			GPRINT:ramlast:"%4.3lf %sB\n" \
			LINE1:bswap#000000:"used SWAP\: " \
			GPRINT:bswaplast:"%4.3lf %sB " \
			LINE1:swap#006600:"free SWAP\: " \
			GPRINT:swaplast:"%4.3lf %sB"]
	end
end


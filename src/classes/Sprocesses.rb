#!RUBYBIN

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


class Sprocesses
	@@config = 0
	@@data = Hash.new 

	def initialize(config)
		@@config = config
		@@data['processes'] = 0
	end

	def mkdb
		%x[#{@@config['rrdtool']} create \
			#{@@config['dbdir']}/#{@@config['processes_prefix']}.rrd \
			--step #{@@config['step']} \
			DS:processes:GAUGE:#{@@config['step']+60}:0:U \
			RRA:AVERAGE:0.5:1:2160 RRA:AVERAGE:0.5:5:2016 \
			RRA:AVERAGE:0.5:15:2880 RRA:AVERAGE:0.5:60:8760 \
			RRA:MAX:0.5:1:2160 RRA:MAX:0.5:5:2016 \
			RRA:MAX:0.5:15:2880 RRA:MAX:0.5:60:8760]
	end

	def get
		@@data['processes'] = 0

		@output = %x[ps hax]
		@output.each do |line|
			@@data['processes'] += 1
		end
	end

	def write
		%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/#{@@config['processes_prefix']}.rrd N:#{@@data['processes']}]
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

		%x[#{@@config['rrdtool']} graph \
			#{@@config['graphdir']}/#{@@config['processes_prefix']}-#{@suffix}.png -i \
			--start #{@start} -a PNG -t "Number of processes" \
			--vertical-label "processes" -w 600 -h 150 \
			--color SHADEA#ffffff --color SHADEB#ffffff \
			--color BACK#ffffff \
			DEF:processes=#{@@config['dbdir']}/#{@@config['processes_prefix']}.rrd:processes:AVERAGE \
			LINE1:processes#ff0000:"Process count" \
			VDEF:auswertung1=processes,AVERAGE \
			GPRINT:auswertung1:"Average process count\\: %lg" \
			DEF:maxaus=#{@@config['dbdir']}/#{@@config['processes_prefix']}.rrd:processes:MAX \
			VDEF:maxaus1=maxaus,MAXIMUM \
			GPRINT:maxaus1:"Maximum process count\\: %lg"]
	end
end


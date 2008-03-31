#!/usr/bin/env ruby

# Copyright (c) 2008 Author
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


class ModuleName
	@config = 0
	@data = Hash.new 

	def initialize(config)
		@config = config
		@data['value'] = 0
	end

	def mkdb
		%x[#{@config['rrdtool']} create \
			#{@config['dbdir']}/@config['load_prefix']}.rrd \
			--step #{@config['step']} \
		]
	end

	def get
		if(@config['os'] == "freebsd6")
			@output = %x[#{@config['src_program']}]
			@output.each do |line|
				# do something...
			end
		elsif(@config['os'] == "linux2.6")
			@output = %x[#{@config['src_program']}]
			@output.each do |line|
				# do something...
			end
		end
	end

	def write
		%x[#{@config['rrdtool']} update #{@config['dbdir']}/@config['_prefix']} N:#{@data['value']}]
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

		%[#{@config['rrdtool']} graph \
			#{@config['graphdir']}/#{@config['_prefix']}-#{@suffix}.rrd -i \
			--start #{@start} -a PNG -t "" \
			--vertical-label "" -w 600 -h 150 \
			--color SHADEA#ffffff --color SHADEB#ffffff \
			--color BACK#ffffff \
		]
end


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
		@@data['fram'] = 0
		@@data['fswap'] = 0
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
		%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/@@config['_prefix']} N:#{@@data['value']}]
	end
end


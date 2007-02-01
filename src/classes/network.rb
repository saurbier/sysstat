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
		@@data['value'] = 0
	end

	def get
		@@config["interfaces"].split().each do |interface|
			if(@config['os'] == "freebsd6")
				@output = %x[netstat -ib]
				@output.each do |line|
					if(line =~ /interface/ 
					   and line =~ /Link/)
						linea = line.split()
						@@data[interface]["in"] = linea[6]
						@@data[interface]["out"] = linea[9]
					end
				end
			elsif(@config['os'] == "linux2.6")
				@output = %x[ifconfig #{interface}]
				@output.each do |line|
					if(line =~ /bytes/) 
						linea = line.split()
						@@data[interface]["in"] = linea[1].split(":")[2]
						@@data[interface]["out"] = linea[8].split(":")[2]
					end
				end
			end
		end
	end

	def write
		@@config["interfaces"].split().each do |interface|
			%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/#{@@config['network_prefix']}-#{interface}.rrd N:#{@@data['#{interface}']['in']}:#{@@data['#{interface}']['out']}]
		end
	end
end


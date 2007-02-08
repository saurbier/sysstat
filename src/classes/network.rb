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

	def mkdb
		@@config["net_interfaces"].split().each do |interface|
			%x[#{@@config['rrdtool']} create \
				#{@@config['dbdir']}/@@config['network_prefix']}-#{interface}.rrd \
				--step #{@@config['step']} \
				DS:in:COUNTER:120:0:U \
				DS:out:COUNTER:120:0:U \
				RRA:AVERAGE:0.5:1:2160 RRA:AVERAGE:0.5:5:2016 \
				RRA:AVERAGE:0.5:15:2880 RRA:AVERAGE:0.5:60:8760 \
				RRA:MAX:0.5:1:2160 RRA:MAX:0.5:5:2016 \
				RRA:MAX:0.5:15:2880 RRA:MAX:0.5:60:8760]
		end
	end

	def get
		@@config["net_interfaces"].split().each do |interface|
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
		@@config["net_interfaces"].split().each do |interface|
			%x[#{@@config['rrdtool']} update #{@@config['dbdir']}/#{@@config['network_prefix']}-#{interface}.rrd N:#{@@data['#{interface}']['in']}:#{@@data['#{interface}']['out']}]
		end
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

		@@config["interfaces"].split().each do |interface|
		    %[#{@@config['rrdtool']} graph \
			#{@@config['graphdir']}/#{@@config['network_prefix']}-#{interface}-#{@suffix}.rrd \
			-i --start #{@start} -a PNG \
			-t "Network Interface #{interface}" \
			--vertical-label "Bits/s" -w 600 -h 150 \
			--color SHADEA#ffffff --color SHADEB#ffffff \
			--color BACK#ffffff \
			COMMENT:"\t\t\t   Current\t\t  Average\t\t Maximum\t  Datenvolumen\n" \
			DEF:r=$DBDIR$NET_PREFIX-$IF.rrd:in:AVERAGE \
			CDEF:rx=r,8,* AREA:rx#00dd00:"Inbound " \
			VDEF:rxlast=rx,LAST GPRINT:rxlast:" %12.3lf %s" \
			VDEF:rxave=rx,AVERAGE GPRINT:rxave:"%12.3lf %s" \
			VDEF:rxmax=rx,MAXIMUM GPRINT:rxmax:"%12.3lf %s" \
			VDEF:rxtotal=r,TOTAL GPRINT:rxtotal:"%12.1lf %sb\n" \
			DEF:t=$DBDIR$NET_PREFIX-$IF.rrd:out:AVERAGE \
			CDEF:txa=t,-8,* CDEF:tx=t,8,* \
			AREA:txa#0000ff:"Outbound " \
			VDEF:txlast=tx,LAST GPRINT:txlast:"%12.3lf %s" \
			VDEF:txave=tx,AVERAGE GPRINT:txave:"%12.3lf %s" \
			VDEF:txmax=tx,MAXIMUM GPRINT:txmax:"%12.3lf %s" \
			VDEF:txtotal=t,TOTAL GPRINT:txtotal:"%12.1lf %sb"]
		end
	end
end


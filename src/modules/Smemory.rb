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


class Smemory
	@@config = 0
	@@data = Hash.new 

	def initialize(config)
		@@config = config
		@@data['fram'] = 0
		@@data['fswap'] = 0
		@@rrd = RRDtool.new("#{@@config['dbdir']}/#{@@config['memory_prefix']}.rrd")
	end

	def mkdb
	  if(!FileTest.exist?(@@rrd.rrdname))
	    @@rrd.create(@@config['step']), Time.now.to_i-1,
			  ["DS:ram:GAUGE:#{@@config['step']+60}:0:U",
			   "DS:swap:GAUGE:#{@@config['step']+60}:0:U", 
			   "RRA:AVERAGE:0.5:1:2160", "RRA:AVERAGE:0.5:5:2016",
			   "RRA:AVERAGE:0.5:15:2880", "RRA:AVERAGE:0.5:60:8760"]
		end
	end

	def get
		if(@@config['os'] == "freebsd6")
			@output = %x[vmstat]
			@output.each do |line|
				@@data['fram'] = line.split()[4].to_i*1024
			end

			@output = %x[swapinfo -k]
			@output.each do |line|
				@@data['fswap'] = line.split()[3].to_i*1024
			end
		elsif(@@config['os'] == "linux2.6")
			@output = File.new("/proc/meminfo", "r") 
			@output.each do |line|
				if(line =~ /MemFree:/)
					@@data['fram'] = line.split()[1].to_i*1024
				elsif(line =~ /SwapFree:/)
					@@data['fswap'] = line.split()[1].to_i*1024
				end
			end
			@output.close
		end
	end

	def write
	  @@rrd.update("ram:swap", ["N:#{@@data['fram']}:#{@@data['fwap']}"])
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

    @@rrd.graph(
      ["#{@@config['graphdir']}/#{@@config['memory_prefix']}-#{@suffix}.png",
			 "--title", "RAM and Swap usage",
			 "--start", "#{@start}", 
			 "--interlace",
			 "--imgformat", "PNG",
			 "--width=600", "--height=150",
			 "--vertical-label", "Bytes"
			 "--color", "SHADEA#ffffff",
			 "--color", "SHADEB#ffffff",
			 "--color", "BACK#ffffff",
			 "DEF:ram=#{@@rrd.rrdname}:ram:AVERAGE",
			 "DEF:swap=#{@@rrd.rrdname}:swap:AVERAGE",
			 "CDEF:bram=#{@@config['mem_ramtotal']},ram,-",
			 "CDEF:bswap=#{@@config['mem_swaptotal']},swap,-",
			 "AREA:bram#99ffff:\"used RAM\\: \"",
			 "VDEF:bramlast=bram,LAST", "VDEF:ramlast=ram,LAST",
			 "VDEF:bswaplast=bswap,LAST", "VDEF:swaplast=swap,LAST",
			 "GPRINT:bramlast:\"%4.3lf %sB\"",
			 "LINE1:ram#ff0000:\"free RAM\\: \"",
			 "GPRINT:ramlast:\"%4.3lf %sB\\n\"",
			 "LINE1:bswap#000000:\"used SWAP\\: \"",
			 "GPRINT:bswaplast:\"%4.3lf %sB \"",
			 "LINE1:swap#006600:\"free SWAP\\: \"",
			 "GPRINT:swaplast:\"%4.3lf %sB\""])
	end
end


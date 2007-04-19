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


# Initialize modules
def initialize
  @config['modules'].split().each do |modul|
	  # Load modules and initialize them
	  require "#{modul}.rb"
	  @modules[modul] = Object.const_get(modul).new(@config)

	  # Check if databases exist and create if needed
    #	@modules[modul].mkdb
  end
end

# Childs for getting data and writing to database
def get_data
	@childs["data"] = Process.fork do 
		trap("SIGHUP") { Process.exit!(0) }
		trap("SIGTERM") { Process.exit!(0) }

		time = Time.now

		loop do
			if(time <= Time.now)
				time = Time.now + @config['step']
				@config['modules'].split().each do |modul|
					@modules[modul].get
					@modules[modul].write
				end
			end
			sleep 30
		end
	end
end

# Childs for creating graphics 
def create_graphs
	@childs["graph"] = Process.fork do 
		trap("SIGHUP") { Process.exit!(0) }
		trap("SIGTERM") { Process.exit!(0) }
	
		time = Time.now
	
		loop do
			if(time <= Time.now)
				time = Time.now + @config['graph_interval']
				@config['modules'].split().each do |modul|
					@modules[modul].graph("day")
					@modules[modul].graph("week")
					@modules[modul].graph("month")
					@modules[modul].graph("year")
				end
			end
			sleep 30
		end
	end
end

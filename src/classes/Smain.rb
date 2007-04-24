#!/usr/bin/env ruby

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


class Smain
  @@childs = Hash.new
  @@modules = Hash.new
  @@config = Hash.new
  
  def initialize(config)
    # Read configuration file and set values in @@config hash
    f = File.open(config)
    f.each do |line|
      if(line =~~/^#/)
        continue
      elsif(line =~ /^\n/)
        continue
      else
        linea = line.split(/ /)
        @@config[linea[0]] = linea[2]
      end
    end
    f.close
    
    # Initialize modules
    @@config['modules'].split().each do |modul|
	    # Load modules and initialize them
	    require "#{modul}.rb"
	    @@modules[modul] = Object.const_get(modul).new(@@config)

	    # Checks if databases exist and create if needed
      @@modules[modul].mkdb
    end
  end

  # Childs for getting data and writing to database
  def get_data
	  @@childs["data"] = Process.fork do
      # Ignore HANUP signal
      trap('HUP', 'IGNORE')
      
      # Exit on SIGTERM or SIGKILL
		  trap("SIGTERM") { Process.exit!(0) }
		  trap("SIGKILL") { Process.exit!(0) }

      # Initialize time object
		  time = Time.now

      # Get and write data in endless loop
		  loop do
		    # Check if enough time since last update has gone
			  if(time <= Time.now)
			    # Increment time object with @@config['step'] seconds
				  time = Time.now + @@config['step']
				  
				  # Get and write data for every module
				  @@config['modules'].split().each do |modul|
					  @@modules[modul].get
					  @@modules[modul].write
				  end
			  end
			  
			  # Sleep until next run
			  sleep 30
		  end
	  end
  end

  # Childs for creating graphics 
  def create_graphs
	  @@childs["graph"] = Process.fork do
	    # Ignore HANUP signal
      trap('HUP', 'IGNORE')
      
      # Exit on SIGTERM or SIGKILL
		  trap("SIGTERM") { Process.exit!(0) }
		  trap("SIGKILL") { Process.exit!(0) }

      # Initialize time object	
		  time = Time.now
	
      # Create graphs in endless loop
		  loop do
		    # Check if enough time since last update has gone
			  if(time <= Time.now)
			    # Increment time object with @@config['graph_interval'] seconds
				  time = Time.now + @@config['graph_interval']
				  
				  # Create graphs for every module
				  @@config['modules'].split().each do |modul|
					  @@modules[modul].graph("day")
					  @@modules[modul].graph("week")
					  @@modules[modul].graph("month")
					  @@modules[modul].graph("year")
				  end
			  end
			  
			  # Sleep until next run
			  sleep 60
		  end
	  end
  end

  def kill_childs
    # Send all childs a KILL signal
    @@childs.each do |name pid|
  	  Process.kill("SIGKILL", pid)
    end
  end
end

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

# Ingore HANGUP signal
Signal.trap('HUP', 'IGNORE')

@conffile = "INSTALLDIR/etc/sysstat.conf"
@childs = Hash.new
@modules = Hash.new
@config = Hash.new
$SVERSION = "2.7"

# Load main functions
#require "getoptlong.rb"
require "rubygems"
require "RRDtool"

# Get arguments
#opts = GetoptLong.new
#opts.ordering(GetoptLong::PERMUTE)
#opts.set_options(
#  ['--config-file',   '-c', GetoptLong::REQUIRE_ARGUMENT],
#  ['--help',          '-h', GetoptLong::NO_ARGUMENT],
#  ['--version',       '-v', GetoptLong::NO_ARGUMENT])
#opts.each do |name arg|
#  case(name)
#    when("--config-file")
#      @conffile = arg
#
#    when("--help")
#      # Display help message
#      puts "help"
#
#    when("--version")
#      # Display Version
#      puts "Sysstat #{$SVERSION}"
#  end
#end
#opts.terminate


# Read configuration file and set values in @@config hash
f = File.open(@conffile)
f.each do |line|
  if(line =~ /^\#/ or line =~ /^\n/)
  else
    linea = line.split(/=/)
    if(linea[0] == "step" or linea[0] == "graph_interval")
      @config[linea[0]] = linea[1].strip!.squeeze(" ").to_i
    else
      @config[linea[0]] = linea[1].strip!.squeeze(" ")
    end
  end
end
f.close

# Add lib directories to include path
$: << "#{@config['installdir']}/lib"

# Initialize modules
@config['modules'].split().each do |modul|
  # Load modules and initialize them
  require "#{modul}.rb"
  @modules[modul] = Object.const_get(modul).new(@config)

  # Checks if databases exist and create if needed
  @modules[modul].mkdb
end

# Childs for getting data and writing to database
@childs["data"] = Process.fork do
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
      time = Time.now + @config['step']

      # Get and write data for every module
      @config['modules'].split().each do |modul|
        @modules[modul].get
        @modules[modul].write
      end
    end

    # Sleep until next run
    sleep 30
  end
end

# Childs for creating graphics
@childs["graph"] = Process.fork do
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
      time = Time.now + @config['graph_interval']

      # Create graphs for every module
      @config['modules'].split().each do |modul|
        @modules[modul].graph("day")
        @modules[modul].graph("week")
        @modules[modul].graph("month")
        @modules[modul].graph("year")
      end
    end

    # Sleep until next run
    sleep 60
  end
end

def kill_childs
  # Send all childs a KILL signal
end
# Initialize main routines
@sysstat = Smain.new(@config)

# Start child processes
@sysstat.get_data
@sysstat.create_graphs

# Restart on SIGUSR1
trap("SIGUSR1") do
  # Kill child processes
  @sysstat.kill_childs
  
  # Reinitialize main routines (and configuration)
  @sysstat = Smain.new(@config)
  
  # Restart child processes
  @sysstat.get_data
  @sysstat.create_graphs
end

# Kill child processes on SIGKILL or SIGTERM
trap("SIGKILL") do
  @childs.each do |name, pid|
    Process.kill("SIGKILL", pid)
  end
end
trap("SIGTERM") do
  @childs.each do |name, pid|
    Process.kill("SIGTERM", pid)
  end
end

# Wait for child processes
Process.wait

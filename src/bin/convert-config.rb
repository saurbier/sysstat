#!/usr/bin/env ruby

# Copyright (c) 2006-2008 Konstantin Saurbier <konstantin@saurbier.net>
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


# Load modules and classes
require "getoptlong.rb"
#require "FileUtils"
require "yaml"

$VERSION = 1
$SVERSION = 2.17

# Get arguments
options = GetoptLong.new
options.set_options(
  ['--config-file',   '-c', GetoptLong::REQUIRED_ARGUMENT],
  ['--help',          '-h', GetoptLong::NO_ARGUMENT],
  ['--version',       '-v', GetoptLong::NO_ARGUMENT])
options.each_option do |name, arg|
  case(name)
    when("--config-file")
      @configfile = arg

    when("--help")
      # Display help message
      puts "Usage: convert-config.rb [option...]"
      puts "Options:"
      puts "  -c FILE  --config-file FILE    Use config file FILE"
      puts "  -h  --help                     Output this help, then exit"
      puts "  -v  --version                  Output version number, then exit"
      Kernel.exit!

    when("--version")
      # Display Version
      puts "convert-config.rb version #{$VERSION}"
      puts "  Converts old-style configurations to new YAML-based configurations."
      puts "  part of Sysstat #{$SVERSION}"
      puts "  (c)2006-2008 Konstantin Saurbier"
      Kernel.exit!
  end
end
options.terminate


@config = Hash.new
@config["Smain"] = Hash.new
%x[grep modules #{@configfile}].split(/=/)[1].strip!.squeeze(" ").split().each do |mod|
  @config[mod] = Hash.new
end

# Read old configuration file
f = File.open(@configfile)
f.each do |line|
  if(line =~ /^#/ or line =~ /^\n/)
  else
    linea = line.split(/=/)
        
    # Sconnections module
    if(linea[0] =~ /^connections/)
      @config["Sconnections"]["prefix"] = linea[1].strip!.squeeze(" ")

    # Scpu module
    elsif(linea[0] =~ /^cpu/)
      @config["Scpu"]["prefix"] = linea[1].strip!.squeeze(" ")

    # Sdisk module
    elsif(linea[0] =~ /^hdds/)
      if(linea[0] == "modules" or linea[0] == "hdds")
        @config["Sdisk"]["devices"] = linea[1].strip!.squeeze(" ").split()
      elsif(linea[0] == "hdds_prefix")
        @config["Sdisk"]["prefix"] = linea[1].strip!.squeeze(" ")
      else
        @config["Sdisk"][linea[0]] = linea[1].strip!.squeeze(" ")
      end
      
    # Sload module
    elsif(linea[0] =~ /^load/)
      @config["Sload"]["prefix"] = linea[1].strip!.squeeze(" ")

    # Smemory module
    elsif(linea[0] =~ /^mem/)
      if(linea[0] == "mem_ramtotal" or linea[0] == "mem_swaptotal")
        @config["Smemory"][linea[0].gsub(/mem_/,"")] = linea[1].strip!.squeeze(" ").to_i
      elsif(linea[0] == "memory_prefix")
        @config["Smemory"]["prefix"] = linea[1].strip!.squeeze(" ")
      else
        @config["Smemory"][linea[0].gsub(/mem_/,"")] = linea[1].strip!.squeeze(" ")
      end
    
    # Snetwork module
    elsif(linea[0] =~ /^net/)
      if(linea[0] == "net_interfaces")
        @config["Snetwork"]["interfaces"] = linea[1].strip!.squeeze(" ").split()
      elsif(linea[0] == "network_prefix")
        @config["Snetwork"]["prefix"] = linea[1].strip!.squeeze(" ")
      else
        @config["Snetwork"][linea[0].gsub(/net_/,"")] = linea[1].strip!.squeeze(" ")
      end

    # Sprocess module
    elsif(linea[0] =~ /^process/)
      @config["Sprocesses"]["prefix"] = linea[1].strip!.squeeze(" ")

    # General configuration
    elsif(linea[0] == "step" or linea[0] == "graph_interval")
      @config["Smain"][linea[0]] = linea[1].strip!.squeeze(" ").to_i
    elsif(linea[0] == "modules")
      @config["Smain"][linea[0]] = linea[1].strip!.squeeze(" ").split()
    else
      @config["Smain"][linea[0]] = linea[1].strip!.squeeze(" ")
    end
  end
end
f.close

#FileUtils.move(@configfile,@configfile+".orig")

#file = File.new(@configfile+".new", "w+")
file = File.new(@configfile, "w+")
file.write(YAML::dump(@config))
file.close


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

@config = "INSTALLDIR/etc/sysstat.conf"
$SVERSION = "2.7"

# Add lib directories to include path
$: << "INSTALLDIR/lib"

# Load main functions
#require "getoptlong.rb"
require "RRDtool"
require "Smain.rb"

# Get arguments
#opts = GetoptLong.new
#opts.ordering(GetoptLong::PERMUTE)
#opts.set_options(
#  ['--config-file',   '-c', GetoptLong::REQUIRE_ARGUMENT],
#  ['--help',          '-h', GetoptLong::NO_ARGUMENT],
#  ['--version',       '-v', GetoptLong::NO_ARGUMENT])
#opts.each_option do |name arg|
#  case(name)
#    when("--config-file")
#      @config = arg
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
trap("SIGKILL") do {@sysstat.kill_childs}
trap("SIGTERM") do {@sysstat.kill_childs}

# Wait for child processes
Process.wait

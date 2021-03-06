#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2006-2013 Konstantin Saurbier <konstantin@saurbier.net>
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
  def initialize(conffile)
    @childs = Hash.new
    @modules = Hash.new
    @config = Hash.new

    # Read configuration file and set values in @config hash
    @config = YAML.load(File.open(conffile))

    # Set values for available ram and swap
    if(@config['Smain']['os'] == "freebsd6")
      @config['Smemory']['ramtotal'] = %x[sysctl -n hw.physmem].to_i/1024
      @config['Smemory']['swaptotal'] = %x[swapinfo -k | tail -1 | awk '{print $2}'].to_i
    elsif(@config['Smain']['os'] == "linux2.6")
      @config['Smemory']['ramtotal'] = %x[cat /proc/meminfo | grep -w "MemTotal:" | awk '{print $2}'].to_i
      @config['Smemory']['swaptotal'] = %x[cat /proc/meminfo | grep -w "SwapTotal:" | awk '{print $2}'].to_i
    end


    # Initialize modules
    @config["Smain"]['modules'].each do |modul|
      # Load modules and initialize them
      require "#{modul}.rb"
      @modules[modul] = Object.const_get(modul).new("Smain" => @config["Smain"], modul => @config[modul])

      # Checks if databases exist and create if needed
      @modules[modul].mkdb
    end
  end

  # Childs for getting data and writing to database
  def get_data
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
          # Increment time object with @config['step'] seconds
          time = Time.now + @config["Smain"]['step']

          # Get and write data for every module
          @config["Smain"]['modules'].each do |modul|
            @modules[modul].get
            @modules[modul].write
          end
        end

        # Sleep until next run
        sleep 30
      end
    end
  end

  # Childs for creating graphics
  def create_graphs
    if(@config["Smain"]["graphs"] == "interval")
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
            # Increment time object with @config['graph_interval'] seconds
            time = Time.now + @config["Smain"]['graph_interval']

            # Create graphs for every module
            @config["Smain"]['modules'].each do |modul|
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
    end
  end

  def config
    return @config
  end

  def modules
    return @modules
  end

  def kill_childs
    # Send all childs a TERM signal
    @childs.each do |name, pid|
      Process.kill("SIGTERM", pid)
    end

    sleep 3

    # Send all childs a KILL signal
    @childs.each do |name, pid|
      Process.kill("SIGKILL", pid)
    end
  end
end

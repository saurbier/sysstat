#!/usr/local/bin/ruby -w

@config = Hash.new

## Operating System
# One of freebsd6, linux2.6
@config['os'] = "OS"

## Time between data gathering steps
# (in seconds)
@config['step'] = 300

## Time between graph creatings
# (in seconds)
@config['graph_interval'] = 900


### Paths 
## Full path of rrdtool 1.2.x
@config['rrdtool'] = "RRDTOOL"

## Location of the installation
@config['installdir'] = "INSTALLDIR"

## Location of the database files
@config['dbdir'] = "DBDIR"

## Output directory for the graphics
@config['dbdir'] = "GRAPHDIR"


### Modules
## Active modules
# List of modules separated with a space
@config['modules'] = "MODULES"

## Prefix definitions for rrd and graph files
@config['connections_prefix'] = "connections"
@config['cpu_prefix'] = "cpu"
@config['load_prefix'] = "load"
@config['memory_prefix'] = "memory"
@config['network_prefix'] = "net"
@config['processes_prefix'] = "processes"

## Memory module specific configuration
# Available RAM and Swap
@config['mem_ramtotal'] = "RAMTOTAL"
@config['mem_swaptotal'] = "SWAPTOTAL"

## Network module specific configuration
# Graphed interfaces
@config['net_interfaces']


### Version
@config['version'] = "2.0.0"


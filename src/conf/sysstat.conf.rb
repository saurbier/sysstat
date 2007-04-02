#!/usr/local/bin/ruby -w

@config = Hash.new

## Operating System
# One of freebsd6, linux2.6
@config['os'] = "freebsd6"

## Time between data gathering steps
# (in seconds)
@config['step'] = 300

## Time between graph creatings
# (in seconds)
@config['graph_interval'] = 900


### Paths 
## Full path of rrdtool 1.2.x
@config['rrdtool'] = "/usr/local/bin/rrdtool"

## Location of the installation
@config['installdir'] = "/homes/saurbier/tmp/sysstat"

## Location of the database files
@config['dbdir'] = "/homes/saurbier/tmp/sysstat/db"

## Output directory for the graphics
#@config['graphdir'] = "/homes/saurbier/tmp/sysstat/output"
@config['graphdir'] = "/vol/stats/xdf02_sysstat2"


### Modules
## Active modules
# List of modules separated with a space
@config['modules'] = "Sconnections Scpu Sload Smemory Snetwork Sprocesses"

## Prefix definitions for rrd and graph files
@config['connections_prefix'] = "connections"
@config['cpu_prefix'] = "cpu"
@config['load_prefix'] = "load"
@config['memory_prefix'] = "memory"
@config['network_prefix'] = "net"
@config['processes_prefix'] = "processes"

## Memory module specific configuration
# Available RAM and Swap
@config['mem_ramtotal'] = 2147483648
@config['mem_swaptotal'] = 4294967296

## Network module specific configuration
# Graphed interfaces
@config['net_interfaces'] = "xl0"


### Version
@config['version'] = "2.0.0"


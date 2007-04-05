#!RUBYBIN

@config = Hash.new

## Operating System
# One of freebsd6, linux2.6
@config['os'] = "OS"

## Time between data gathering steps
# (in seconds)
@config['step'] = STEP

## Time between graph creatings
# (in seconds)
@config['graph_interval'] = GSTEP


### Paths 
## Full path of rrdtool 1.2.x
@config['rrdtool'] = "RRDTOOLBIN"

## Location of the installation
@config['installdir'] = "INSTALLDIR"

## Location of the database files
@config['dbdir'] = "DBDIR"

## Output directory for the graphics
@config['graphdir'] = "GRAPHDIR"


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
@config['mem_ramtotal'] = RAM
@config['mem_swaptotal'] = SWAP

## Network module specific configuration
# Graphed interfaces
@config['net_interfaces'] = "INTERFACES"


### Version
@config['version'] = "2.0.0"


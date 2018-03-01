#!/bin/bash

# 1. - check if mongodb is installed
# 2. - get arguments from command line (amount of shards and replicas), always create mongos - dbpath, dblog
# 3. - create additional directories - logs and data
# 3. - parse arguments, evaluate them
# 4. - make running v0.1 for starting shards

# return values: https://stackoverflow.com/questions/17336915/return-value-in-bash-script

function initialize_instances {
    # Function that receives parsed arguments, starts primary replica sets,
    # configures them, starts secondary replica sets, cfg servers and balancer

}

function extract_options {
    # read all the options from command line
    TEMP=`getopt -o m:r:s:p:l:d: --long mode:,replicas:,shards:,port:,logpath:,datapath: -n 'main.sh' "$@"`
    eval set -- "$TEMP"
}

function show_help {
    # Prints help

    printf "usage:\n"
}

function create_dirs {
    # Creates directories for logging and data

    logpath=$0
    datapath=$1
}

function start_replica_set {
    # Starts one replica set on certain port    

    port=$0
}

function create_pid_file {
    # Creates one PID file on certain port for mongo instance

    port=$0
    type=$1
}

function create_init_string {
    # Creates init string for sharding
}

function kill_instance {
    # Kills one instance on certain port and removes PID file

    port=$0
}

function stop_instance {
    # Stops one instance

    port=$0
}

extract_options "$@"

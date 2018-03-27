#!/bin/bash

# TODO: dynamically generate ports
# TODO: PID files
# TODO: 

# return values: https://stackoverflow.com/questions/17336915/return-value-in-bash-script

# Starts one replica set instance with port number and replica set ID
# $1 ID: integer    - ID of group of replica sets
# $2 PORT: integer  - port number of replica set
function create_replica_set {
    ID=$1
    PORT=$2

    # TODO: create folder for data

    mongod --port $PORT --dbpath $DATADIR/$PORT --logpath $LOGPATH/$PORT.log --fork --replSet "rs${ID}" --shardsvr --smallfiles
}

# Creates config string and adds it to replica set configuration
# $1 ID: integer    - ID of group of replica set
# $2 PORT: integer  - port number of replica set    
function initialize_replica_set {
    ID=$1
    PORT=$2

    initString="rs.initiate({_id: 'rs${ID}', members: [{_id: ${ID}, host: 'localhost:${PORT}'}]}, {force : true})"
    mongo --port $PORT --eval "$initString"
}

# adds another replica set to sharded cluster
# $1 PRIMARY_PORT: integer  - port number of replica sets appropriate shard
# $2 PORT: integer          - port number of replica set
function config_replica_set {
    PRIMARY_PORT=$1
    PORT=$2

    initString="rs.add('localhost:${PORT}')"
    mongo --port $PRIMARY_PORT --eval "$initString"
}

# starts new config server
# $1 ID: integer    - port ID of config server
# $2 PORT:          - port number of config server
function start_config_server {
    ID=$1
    PORT=$2

    mongod --port $PORT --dbpath $DATADIR/${PORT} --configsvr --replSet configReplSet --fork --logpath $LOGPATH/$PORT.log --smallfiles
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

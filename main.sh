#!/bin/bash

# TODO: PID files
# TODO: 

# return values: https://stackoverflow.com/questions/17336915/return-value-in-bash-script

MOGNOD_STARTING_PORT=27017  # port of first replica set
CONFIG_STARTING_PORT=28017  # port of first config server
MONGOD_PORTS=()
CONFIG_PORTS=()

# Generates arrays of ports used later in the programme to start instances
# $1 REPLICAS: integer  - number of mongod instances in one shard
# $2 SHARDS: integer    - number of shards
function generate_ports {
    REPLICAS=$1
    SHARDS=$2

    case "$SHARDS" in   # Checking for valid amount of shards
        0) TOTAL=$REPLICAS ;;
        *) TOTAL=$((REPLICAS * SHARDS)) ;;
    esac

    for ((i = 0; i < TOTAL; i++)); do   # generating array of mongod ports
        MONGOD_PORTS+=($(($MONGOD_STARTING_PORT + $i)))
    done

    if ((SHARDS < 2)); then # generating array of config ports
        CONFIG_PORTS+=($CONFIG_STARTING_PORT)
    else
        for ((i = 0; i < SHARDS; i++)); do
            CONFIG_PORTS+=($(($CONFIG_STARTING_PORT + $i)))
        done
    fi
}

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


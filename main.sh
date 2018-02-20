#!/bin/bash

# 1. - check if mongodb is installed
# 2. - get arguments from command line (amount of shards and replicas), always create mongos - dbpath, dblog
# 3. - create additional directories - logs and data
# 3. - parse arguments, evaluate them
# 4. - make running v0.1 for starting shards

# return values: https://stackoverflow.com/questions/17336915/return-value-in-bash-script

# BONUS - specify range of ports for instances

function extract_options {
    # read all the options from command line
    TEMP=`getopt -o m:r:s:p:l:d: --long mode:,replicas:,shards:,port:,logpath:,datapath: -n 'main.sh' "$@"`
    eval set -- "$TEMP"

    while true; do
        case "$1" in
            -m|--mode)
                case "$2" in
                # go through all the modes: start/stop/reset/clear_log/clear_data/show/help
                    "")
}

function show_help {
    printf "usage:\n"
}

extract_options "$@"

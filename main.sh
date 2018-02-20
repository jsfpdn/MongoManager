#!/bin/bash

# 1. - check if mongodb is installed
# 2. - get arguments from command line (amount of shards and replicas), always create mongos - dbpath, dblog
# 3. - create additional directories - logs and data
# 3. - parse arguments, evaluate them
# 4. - make running v0.1 for starting shards

# BONUS - specify range of ports for instances

function get_params {
    MAIN_PARAM=$1 | tr '[:upper]' '[:lower]'
    printf "$MAIN_PARAM"
    case "$MAIN_PARAM" in
        start)
            # start
            # check if the argument $2 is "use_last" and use the last mongodb configuration
            printf "start"
            ;;
        stop)
            # stop
            printf "stop"
            ;;
        status)
            # what's the status
            printf "status"
            ;;
        help)
            # prints out help
            show_help
            ;;
        *)
            # if anything else, show help
            show_help
            ;;
    esac
}

function show_help {
    printf "usage:\n"
}

get_params
#!/bin/bash

# 1. - check if mongodb is installed
# 2. - get arguments from command line (amount of shards and replicas), always create mongos - dbpath, dblog
# 3. - create additional directories - logs and data
# 3. - parse arguments, evaluate them
# 4. - make running v0.1 for starting shards

# return values: https://stackoverflow.com/questions/17336915/return-value-in-bash-script

# BONUS - specify range of ports for instances

function get_params {
    MAIN_PARAM=$1
    printf "$#"
    case "$MAIN_PARAM" in
        start)
            # start
            # check the arguments first
            if [ "$#" -lt 1 ]; then
                printf "whole lot of argumets bby!\n"
                # check if the argument $2 is "use_last" and use the last mongodb configuration
            else
                printf "err: wrong arguments\n"
                show_help
            fi
            ;;
        stop)
            # stop
            printf "stop\n"
            ;;
        status)
            # what's the status
            printf "status\n"
            ;;
        help)
            # prints out help
            #show_help
            ;;
        clear_logs)
            # clears out all previous logs, asks for permission
            printf "clearing logs...\n"
            ;;
        clear_data)
            # clears out all data, asks for permission
            printf "clearing database data...\n"
            ;;
        *)
            # if anything else, show help
            show_help
            ;;
    esac
}

function extract_options {
    # read all the options from command line
    TEMP=`getopt `

    while true; do
        case "$1" in
            -a|--
}

function show_help {
    printf "usage:\n"
}

get_params "$@"
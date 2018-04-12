#!bin/bash
#script for exporting data from a production database

# pipes data from one db to another
function pipe {
    FROM_DB_NAME=$1
    FROM_COLLECTION_NAME=$2
    TO_PORT=$3
    IP=$4
    PORT=$5

    mongodump --archive --host $IP --port $PORT -c $FROM_COLLECTION_NAME --db $FROM_DB_NAME  | mongorestore --archive --port $TO_PORT
}

# imports data from an archived file
function import {
    DB_NAME=$1
    NAME=$2
    IP=$3
    PORT=$4

    mongorestore --gzip --archive=$NAME --db $DB_NAME --host $IP --port $PORT
}

# exports data from db
function export {
    DB_NAME=$1
    COLLECTION_NAME=$2
    IP=$3
    PORT=$4

    mongodump --host $IP --port $PORT --db $DB_NAME --collection $COLLECTION_NAME --archive=$DB_NAME-$COLLECTION_NAME.gz --gzip
}

# prints out help
function help {
    echo "'$0 export    -   exports collection'"
    echo "'$0 import    -   exports collection'"
    echo "'$0 pipe      -   exports and immediately imports to collection to desired database'"
}

case $1 in
export)
    read -p "ip address: " IP
    read -p "balancer port: " BALANCER
    read -p "database name: " DB
    read -p "collection name: " COLLECTION
    export $DB $COLLECTION $IP $BALANCER
    ;;
pipe)
    echo "FROM: "
    read -p "ip address: " IP
    read -p "balancer port: " BALANCER
    read -p "database name: " DB
    read -p "collection name: " COLLECTION
    echo "TO: "
    read -p "ip address: " TO_IP
    read -p "port: " TO_PORT
    pipe $DB $COLLECTION $TO_PORT $IP $BALANCER
    ;;
import)
    read -p "ip address: " IP
    read -p "port: " PORT
    read -p "database name: " DB
    read -p "full file name: " FILE_NAME
    import $DB $FILE_NAME $IP $PORT
    ;;
*)
    help
    ;;
esac

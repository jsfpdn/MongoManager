#!bin/bash
# secondary school-leaving work script that manages mongo instances
# author: Josef Podany
# class: V4D
# email: josef.podany.ml@gmail.com

BALANCER_PORT=27017         # mongo balancer port number
MONGOD_PORT=28017           # first port of mongod instances
CONFIG_PORT=29017           # first port of config servers
NUMBER_OF_SHARDS=3          # amount of shards in sharded cluster
NUMBER_OF_REPLICA_SETS=3    # amount of replica sets of one shard
DATADIR=~/mongo/data        # data folder
LOGPATH=~/mongo/logs        # log folder
DB_NAME='mongomanager'      # name of sharded database
DEFAULT_CHUNK_SIZE='64'     # default size of a chunk created by sharding

# Creates list of used ports for mongod
MONGOD_PORTS=()
for ((i = 0; i < NUMBER_OF_REPLICA_SETS * NUMBER_OF_SHARDS; i++)); do
    MONGOD_PORTS+=($(($MONGOD_PORT + $i)))
done

# Creates list of ports for config servers
CONFIG_PORTS=()
for i in {0..2}; do
    CONFIG_PORTS+=($(($CONFIG_PORT + $i)))
done

# starts new replica set
# $1 ID:integer     - port ID of replica set
# $2 PORT:integer   - port number of replica set
function startReplicaSet {
    ID=$1
    PORT=$2

    if [ ! -d “$DATADIR/$PORT/” ]; then
        mkdir -p $DATADIR/$PORT
    fi

    mongod --port $PORT --dbpath $DATADIR/$PORT --logpath $LOGPATH/$PORT.log  --fork --replSet "rs${ID}" --shardsvr --smallfiles
}

# initiates already started replica set
# $1 ID:integer     - port ID of replica set
# $2 PORT:integer   - port number of replica set
function configReplicaSet {
    ID=$1
    PORT=$2

    initString="rs.initiate({_id: 'rs${ID}', members: [{_id: ${ID}, host: 'localhost:${PORT}'}]}, {force : true})"
    mongo --port $PORT --eval "$initString"
}

# starts new config server
# $1 ID:integer     - port ID of config server
# $2 PORT:integer   - port number of config server
function startConfigServer {
    ID=$1
    PORT=$2

    mongod --port $PORT --dbpath $DATADIR/${PORT} --configsvr --replSet configReplSet --fork --logpath $LOGPATH/$PORT.log --smallfiles
}

# adds another replica set to sharded cluster
# $1 PRIMARY_PORT:integer   - port number of replica sets appropriate shard
# $2 PORT:integer           - port number of replica set
function configNewReplicaSet {
    PRIMARY_PORT=$1
    PORT=$2

    initString="rs.add('localhost:${PORT}')"
    mongo --port $PRIMARY_PORT --eval "$initString"
}

# deletes one replica set using ps aux and kill
# $1 PORT:integer   - port number
function deleteReplicaSet {
    PORT=$1
    if (($PORT == $BALANCER_PORT)); then
        PID=$(ps aux | grep mongos | grep ${PORT} | awk '{print $2}')
    else
        PID=$(ps aux | grep mongod | grep ${PORT} | awk '{print $2}')
    fi
    if (($PID)); then
        kill $PID
        if (($PORT != $BALANCER_PORT)); then
            echo "mongod running on port ${PORT} has been killed"
        else
            echo "mongos running on port ${PORT} has been killed"
        fi
    fi
}

# starts ALREADY INSTALLED mongodb instances
function start {

    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        startConfigServer $i ${CONFIG_PORTS[i]}
    done

    CONFIG_SERVERS_STRING=""
    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        if ((${i} + 1 == ${#CONFIG_PORTS[@]})); then
            CONFIG_SERVERS_STRING+="localhost:${CONFIG_PORTS[i]}"
        else
            CONFIG_SERVERS_STRING+="localhost:${CONFIG_PORTS[i]},"
        fi
    done

    COUNTER=-1
    for ((i = 0; i <= (${#MONGOD_PORTS[@]} - 1); i++)); do
        if ((${i} % NUMBER_OF_REPLICA_SETS == 0 || ${i} == 0)); then
            COUNTER=$((COUNTER+1))
        else
            startReplicaSet $COUNTER ${MONGOD_PORTS[i]}
        fi
    done

    mongos --port ${BALANCER_PORT} --configdb configReplSet/${CONFIG_SERVERS_STRING} --fork --logpath ${LOGPATH}/balancer.log

    ADD_SHARDS_STRING=""
    for ((i = 0; i < ${#MONGOD_PORTS[@]}; i++)); do
        if ((${i} % $NUMBER_OF_REPLICA_SETS == 0)); then
            REPLICA_SET=$((${i}/$NUMBER_OF_REPLICA_SETS))
            ADD_SHARDS_STRING+="sh.addShard('rs${REPLICA_SET}/"
            for ((j = 0; j < ${NUMBER_OF_REPLICA_SETS}; j++)); do
                PORT=$((${MONGOD_PORTS[i]} + ${j}))
                if ((${j} == $NUMBER_OF_REPLICA_SETS - 1)); then
                    ADD_SHARDS_STRING+="localhost:${PORT}');"
                else
                    ADD_SHARDS_STRING+="localhost:${PORT},"
                fi
            done
        fi
    done
    mongo localhost:${BALANCER_PORT}/admin --eval ${ADD_SHARDS_STRING}
}

# installs and initiates mongodb instances
function init {

    # create appropriate folders for logs and data
    if [ ! -d “$LOGPATH” ]; then    # directory for logs does not exist
        echo "creating logpath"
        mkdir -p $LOGPATH
    fi

    if [ ! -d “$DATADIR” ]; then    # directory for data does not exist
        echo "creating datadir"
        mkdir -p $DATADIR
    fi

    # start primary replica sets
    COUNTER=0
    for ((i = 0; i < ${#MONGOD_PORTS[@]}; i++)); do
        if ((${i} % NUMBER_OF_REPLICA_SETS == 0)); then     # is primary replica set
            echo "starting replica set at ${MONGOD_PORTS[i]}"
            startReplicaSet $COUNTER ${MONGOD_PORTS[i]}
            COUNTER=$((COUNTER+1))
        fi
    done

    # configure primary replica sets
    COUNTER=0
    for ((i = 0; i < ${#MONGOD_PORTS[@]}; i++)); do
        if ((${i} % NUMBER_OF_REPLICA_SETS == 0)); then     # is primary replica set
            configReplicaSet $COUNTER ${MONGOD_PORTS[i]} 
            COUNTER=$((COUNTER+1))
        fi
    done

    # start secondery replica sets and configure them
    COUNTER=-1
    for ((i = 0; i <= (${#MONGOD_PORTS[@]} - 1); i++)); do
        if ((${i} % NUMBER_OF_REPLICA_SETS == 0 || ${i} == 0)); then    # save port number of primary replica set appropriate to the shard
            PREVIOUS=${MONGOD_PORTS[i]}
            COUNTER=$((COUNTER+1))
        else    # 
            startReplicaSet $COUNTER ${MONGOD_PORTS[i]}
            configNewReplicaSet $PREVIOUS ${MONGOD_PORTS[i]}
        fi
    done

    # config servers
    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        mkdir $DATADIR/${CONFIG_PORTS[i]}
        startConfigServer $i ${CONFIG_PORTS[i]}
    done

    initString="rs.initiate({_id: 'configReplSet', configsvr: true, members: [{_id:0, host: 'localhost:${CONFIG_PORT}'}]})"
    mongo --port $CONFIG_PORT --eval "$initString"

    for ((i = 1; i < ${#CONFIG_PORTS[@]}; i++)); do
        addString="rs.add('localhost:${CONFIG_PORTS[i]}')"
        mongo --port $CONFIG_PORT --eval "$addString"
    done

    CONFIG_SERVERS_STRING=""
    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        if ((${i} + 1 == ${#CONFIG_PORTS[@]})); then
            CONFIG_SERVERS_STRING+="localhost:${CONFIG_PORTS[i]}"
        else
            CONFIG_SERVERS_STRING+="localhost:${CONFIG_PORTS[i]},"
        fi
    done

    #mongos
    mongos --port ${BALANCER_PORT} --configdb configReplSet/${CONFIG_SERVERS_STRING} --fork --logpath ${LOGPATH}/balancer.log

    ADD_SHARDS_STRING=""
    for ((i = 0; i < ${#MONGOD_PORTS[@]}; i++)); do
        if ((${i} % $NUMBER_OF_REPLICA_SETS == 0)); then
            REPLICA_SET=$((${i}/$NUMBER_OF_REPLICA_SETS))
            ADD_SHARDS_STRING+="sh.addShard('rs${REPLICA_SET}/"
            for ((j = 0; j < ${NUMBER_OF_REPLICA_SETS}; j++)); do
                PORT=$((${MONGOD_PORTS[i]} + ${j}))
                if ((${j} == $NUMBER_OF_REPLICA_SETS - 1)); then
                    ADD_SHARDS_STRING+="localhost:${PORT}');"
                else
                    ADD_SHARDS_STRING+="localhost:${PORT},"
                fi
            done
        fi
    done

    mongo localhost:${BALANCER_PORT}/admin --eval ${ADD_SHARDS_STRING}
}

# shards db and collection via shard key
function sharding {
    read -p "name of sharded collection: " COLLECTION_NAME
    read -p "name of the shard key: " SHARD_KEY
    read -p "chunk size (default ${DEFAULT_CHUNK_SIZE}MB): " CHUNK_SIZE
    CHUNK_SIZE=${CHUNK_SIZE:-$DEFAULT_CHUNK_SIZE}

    SHARDING_STRING="sh.enableSharding('${DB_NAME}');db.${COLLECTION_NAME}.createIndex({${SHARD_KEY}:1});sh.shardCollection('${DB_NAME}.${COLLECTION_NAME}', {'${SHARD_KEY}':1});db.settings.save({ _id:'chunksize', value: ${CHUNK_SIZE}})"
    mongo localhost:${BALANCER_PORT}/${DB_NAME} --eval "${SHARDING_STRING}"
    echo "sharding completed"
}

# deletes data of all instances
function delete {
    for ((i = 0; i < ${#MONGOD_PORTS[@]}; i++)); do
        deleteReplicaSet ${MONGOD_PORTS[i]}
    done

    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        deleteReplicaSet ${CONFIG_PORTS[i]}
    done

    for ((i = 0; i < ${#CONFIG_PORTS[@]}; i++)); do
        rm -rf $DATADIR/dbconf$i
    done

    deleteReplicaSet ${BALANCER_PORT}

    if [ ! -d “$LOGPATH/” ]; then
        rm -rf $LOGPATH
    fi

    if [ ! -d “$DATADIR” ]; then
        rm -rf $DATADIR
    fi

    echo "All logs and data have been deleted"
}

# stops all instances
function stop {
    BALANCER=$(ps aux | grep mongos | grep ${BALANCER_PORT} | awk '{print $2}')
    if (($BALANCER)); then
        kill $BALANCER
        echo "mongos running on port ${BALANCER_PORT} has been killed"
    fi

    for PORT in "${MONGOD_PORTS[@]}"; do
        MONGOD=$(ps aux | grep mongod | grep ${PORT} | awk '{print $2}')
        if (($MONGOD)); then
            kill $MONGOD
            echo "mongod running on port ${PORT} has been killed"
        fi
    done

    for PORT in "${CONFIG_PORTS[@]}"; do
        CONFIG=$(ps aux | grep mongod | grep ${PORT} | awk '{print $2}')
        if (($CONFIG)); then
            kill $CONFIG
            echo "mongod running on port ${PORT} has been killed"
        fi
    done

    echo 'All processess have been terminated'
}

# prints out help
function help {
    echo "'$0 init      - initial install of mongodb replica sets'"
    echo "'$0 sharding' - shards database and its collection"
    echo "'$0 start'    - starts mongod services"
    echo "'$0 stop'     - stops mongod services"
    echo "'$0 delete'   - deletes all data from mongodb"
}


# switch
case $1 in
start)
    start
    ;;
stop)
    stop
    ;;
sharding)
    sharding
    ;;
init)
    init
    ;;
delete)
    delete
    ;;
*)
    help
    ;;
esac

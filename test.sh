REPLICAS=2
SHARDS=0

MONGOD_STARTING_PORT=27017
CONFIG_STARTING_PORT=28017

MONGOD_PORTS=()
CONFIG_PORTS=()

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

generate_ports $REPLICAS $SHARDS
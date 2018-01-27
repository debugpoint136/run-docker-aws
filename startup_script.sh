#!/usr/bin/env bash

PGSQL_DATA_PATH='/data/pg'
SERVER_CONTAINER="postgresql-server"
DATA_CONTAINER="postgresql-data"

function getStatus(){
    CONTAINER_ID=$(docker ps -a | grep -v Exit | grep $SERVER_CONTAINER | awk '{print $1}')
    if [[ -z $CONTAINER_ID ]] ; then
        echo 'Not running.'
        return 1
    else
        echo "Running in container: $CONTAINER_ID"
        return 0
    fi
}

case "$1" in
    start)
        if [ ! -d $PGSQL_DATA_PATH ]; then
            mkdir -p $PGSQL_DATA_PATH
        fi

        docker ps -a | grep -q $DATA_CONTAINER
        if [ $? -ne 0 ]; then
            docker run --name $DATA_CONTAINER -v $PGSQL_DATA_PATH:/data ubuntu /bin/bash
        fi

        docker ps -a | grep -v Exit | grep -q $SERVER_CONTAINER
        if [ $? -ne 0 ]; then
            CONTAINER_ID=$(docker run -d -p 5432:5432 --volumes-from $DATA_CONTAINER \
                --name $SERVER_CONTAINER kamui/postgresql)
        fi
        getStatus
        ;;

    status)
        getStatus
        ;;

    stop)
        CONTAINER_ID=$(docker ps -a | grep -v Exit | grep $SERVER_CONTAINER | awk '{print $1}')
        if [[ -n $CONTAINER_ID ]] ; then
            SRV=$(docker stop $CONTAINER_ID)
            SRV=$(docker rm $CONTAINER_ID)
            if [ $? -eq 0 ] ; then
                echo 'Stopped.'
                DATA=$(sudo docker ps -a | grep $DATA_CONTAINER |  awk '{print $1}')
                DATA=$(sudo docker rm $DATA)
            fi
        else
            echo 'Not Running.'
            exit 1
        fi
        ;;

    *)
        echo "Usage: `basename $0`  {start|stop|status}"
        exit 1
        ;;
esac

exit 0
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

scp -i "/home/dpuru/EC2-Docker.pem" GM-AM-6S-GM-174_S3_L007_R1_001.fastq.gz ec2-user@ec2-34-236-170-70.compute-1.amazonaws.com:/home/ec2-user/raw_files

scp -i "/home/dpuru/EC2-Docker.pem" GM-AM-6S-GM-174_S3_L007_R1_001.fastq.gz ec2-user@ec2-34-236-192-42.compute-1.amazonaws.com:/home/ec2-user/raw_files
ssh -i "/home/dpuru/EC2-Docker.pem" ec2-user@ec2-34-236-192-42.compute-1.amazonaws.com
ssh -i "EC2-Docker.pem" ec2-user@ec2-34-236-192-42.compute-1.amazonaws.com

sudo usermod -aG docker $USER

sudo vi /etc/sysconfig/docker-storage
--storage-opt dm.basesize=100GB
sudo service docker restart
# extend docker's access to additional EBS attached to EC2 instance
# sudo vgextend docker /dev/xvdcy
# sudo lvextend -L+50G /dev/docker/docker-pool

# how to make an EBS block available to use
lsblk
sudo file -s /dev/nvme1n1
sudo mkfs -t ext4 /dev/nvme1n1

sudo mkdir /docker
sudo mount /dev/nvme1n1 /docker

## move the below lines into above format
INPUT_FILE_1="GM-AM-6S-GM-174_S3_L007_R1_001.fastq.gz"
#INPUT_FILE_2=""
INPUT_TYPE="SE"
REFERENCE_GENOME="mm10"
NUM_THREADS="16"
MARKER="AGGCAGAA"

# create a container called "container_name", as what ever you want, running in the background
docker run --name atac_pipeline -d -it zhanglab/atac-seq:mm10

# copy input files into container atac
docker cp INPUT_FILE_1 atac_pipeline:/data/INPUT_FILE_1
# if it is paired-end data
# docker cp INPUT_FILE_2 atac_pipeline:/data/INPUT_FILE_2

# run our QC pipeline
docker exec -i atac_pipeline bash /atac_seq/pipe_code/atac_pipe_v1.sh \
    -o INPUT_FILE_1 \
    -p INPUT_FILE_2 \
    -g REFERENCE_GENOME -r INPUT_TYPE 

# copy results from container to current working directory
docker cp atac_pipeline:/data/ data

# remember to stop and remove background container
docker stop atac_pipeline
docker rm atac_pipeline
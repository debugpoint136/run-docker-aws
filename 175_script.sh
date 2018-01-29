#!/bin/bash
INPUT_FILE_1="GM-AM-6S-GM-175_S4_L007_R1_001.fastq.gz"
#INPUT_FILE_2=""
INPUT_TYPE="SE"
REFERENCE_GENOME="mm10"
NUM_THREADS="16"
MARKER="TCCTGAGC"

# create a container called "container_name", as what ever you want, running in the background
# docker run --name atac_pipeline -d -it zhanglab/atac-seq:full

# copy input files into container atac
docker cp $INPUT_FILE_1 atac_pipeline:/data/$INPUT_FILE_1
# if it is paired-end data
# docker cp INPUT_FILE_2 atac_pipeline:/data/INPUT_FILE_2

# run our QC pipeline
docker exec -i atac_pipeline bash /atac_seq/pipe_code/atac_pipe_v1.sh \
    -o $INPUT_FILE_1 \
    -g $REFERENCE_GENOME -r $INPUT_TYPE -m $MARKER -t $NUM_THREADS
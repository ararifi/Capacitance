#!/bin/bash

#------------------------------------------------------------
# CONFIG 
#------------------------------------------------------------

source config.sh

#------------------------------------------------------------
# INPUT
#------------------------------------------------------------

# default values
simName=""
meshName=""
configName="" 
meshName=""
cpus="1"

while getopts 's:m:c:i:n:' opt
do 
    case $opt in
        # specifically the prefix like name_ind
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        i) ind="$OPTARG";;
        n) cpus="$OPTARG";;
    esac
done

if [ -z "$simName" ]; then
    echo "ERROR: No simulation name provided. Exiting..."
    exit 1
fi

if [ ! -z $SLURM_ARRAY_TASK_ID ]; then
    ind=$SLURM_ARRAY_TASK_ID
fi
#------------------------------------------------------------
# RUN
#------------------------------------------------------------

./run.sh -s ${simName}_${ind} -c ${configName}_${ind}

#for (( i=$startInd; i<=$endInd; i++ ))
#do
#    echo "Running simulation $i"    
#    if [ -z "$meshName" ]; then
#        
#    else
#        ./run.sh -s ${simName}_${i} -c ${meshName} -m ${meshName}
#    fi
#done

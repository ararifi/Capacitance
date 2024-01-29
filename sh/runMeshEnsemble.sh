#!/bin/bash

#------------------------------------------------------------
# CONFIG
#------------------------------------------------------------

source ./ensembleConfig.sh

#------------------------------------------------------------
# INPUT
#------------------------------------------------------------

# default values
simName=""
meshName=""
configName="" 
meshName=""
cpus="1"

while getopts 'm:c:M:p:i:' opt
do 
    case $opt in
        # specifically the prefix like name_ind
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        p) settingName="$OPTARG";;
        M) mem="$OPTARG";;
        i) index="$OPTARG";;
    esac
done

if [ -z "$configName" ]; then
    echo "ERROR: No config name provided. Exiting..."
    exit 1
fi

if [ -z "$settingName" ]; then
    echo "ERROR: No setting name provided. Exiting..."
    exit 1
fi

if [ -z "$meshName" ]; then 
    meshName="$configName"
    echo "WARNING: No mesh name provided. Using config name instead: $configName"
fi


#------------------------------------------------------------
# RUN
#------------------------------------------------------------

if [ -z "$index" ]; then
    
fi

# jobID=""
# if [[ -z "$SLURM_ARRAY_JOB_ID" ]]; then
#     jobID="${SLURM_JOB_ID}_0"
# else
#     jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
# fi
# jobName="${simName}_${jobID}"

configNames="$( get_configNames $dirConfig $configName)"

indices="$( extract_indices $configNames )"

get_index_config="$( get_index_config $indices $index )"




run_by_indices_parallel $indices "./runMesh.sh"
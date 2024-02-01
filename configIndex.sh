#!/bin/bash

if [ ! -z "$SLURM_ARRAY_TASK_ID" ]; then
    index=$SLURM_ARRAY_TASK_ID
fi

if [ ! -z "$index" ]; then 
    simName="${simName}_${index}"
    configName="${configName}_${index}"
    settingName="${settingName}_${index}"
    meshName="${meshName}_${index}"
    meshNameIn="${meshNameIn}_${index}"
    if [ ! -z "$meshNameOut" ]; then
        meshNameOut="${meshNameOut}_${index}"
    fi 
fi


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

while getopts 'm:c:M:p:' opt
do 
    case $opt in
        # specifically the prefix like name_ind
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        p) settingName="$OPTARG";;
        M) mem="$OPTARG";;
    esac
done

if [ -z "$configName" ]; then
    echo "ERROR: No config name provided. Exiting..."
    exit 1
fi

if [ -z "$meshName" ]; then 
    meshName="$configName"
    echo "WARNING: No mesh name provided. Using config name instead: $configName"
fi

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

configNames="$( find $dirConfig -maxdepth 1 -name "${configName}*" -type f -exec basename {} \; | sed 's/\.[^.]*$//' | sed 's/\.[^.]*$//' )"
# extract the config names without suffix
indices="$( echo "$configNames" | grep -oP '\d+' | sort -n )"

if [ -z "$meshName" ]; then
    echo $configNames | tr ' ' '\n' | parallel "./runMesh.sh -m "{}" -c "{}" -M "$mem" -C -p "$settingName""
else
    echo $indices | tr ' ' '\n' | parallel "./runMesh.sh -m "${meshName}_{}"  -c "${configName}_{}" -M "$mem" -C -p "$settingName""
fi

#./run.sh -s ${simName}_${ind} -c ${configName}_${ind} -n ${cpus} 

#for (( i=$startInd; i<=$endInd; i++ ))
#do
#    echo "Running simulation $i"    
#    if [ -z "$meshName" ]; then
#        
#    else
#        ./run.sh -s ${simName}_${i} -c ${meshName} -m ${meshName}
#    fi
#done

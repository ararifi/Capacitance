#!/bin/bash

#------------------------------------------------------------
# INPUT
#------------------------------------------------------------

# default values
simName=""
meshName=""
configName="" 
meshName=""
cpus="1"

while getopts 's:m:c:N:M:' opt
do 
    case $opt in
        # specifically the prefix like name_ind
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        N) cpus="$OPTARG";;
        M) mem="$OPTARG";;
    esac
done

if [ -z "$configName" ]; then
    echo "ERROR: No config name provided. Exiting..."
    exit 1
fi

if [ -z "$simName" ]; then
    simName="$configName"
    echo "WARNING: No simulation name provided. Using config name instead: $simName"
fi

if [ -z "$meshName" ]; then 
    meshName="$configName"
    echo "WARNING: No mesh name provided. Using config name instead: $configName"
fi

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

configNames="$( find $dirConfig -maxdepth 1 -name "${configName}*" -type f -exec basename {} \; | sed 's/\.[^.]*$//' )"
# extract the config names without suffix
indices="$( echo "$configNames" | grep -oP '(?<=_)\d+' | sort -n )"
if [ -z "$meshName" ]; then
    echo $configNames | tr ' ' '\n' | parallel "./run.sh -s "{}" -c "{}"  -N "$cpus" -M "$mem" -C"
else
    echo $indices | tr ' ' '\n' | parallel "./run.sh -s "${simName}_{}" -c "${configName}_{}" -m "${meshName}_{}" -N "$cpus" -M "$mem" -C"
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

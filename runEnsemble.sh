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
configName="" 
meshName=""

while getopts 's:c:a:b:' opt
do 
    case $opt in
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        a) startInd="$OPTARG";;
        b) endInd="$OPTARG";;
    esac
done

if [ -z "$simName" ]; then
    echo "ERROR: No simulation name provided. Exiting..."
    exit 1
fi

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

for (( i=$startInd; i<=$endInd; i++ ))
do
    echo "Running simulation $i"    
    if [ -z "$meshName" ]; then
        ./run.sh -s ${simName}_${i} -c ${configName}_${i}
    else
        ./run.sh -s ${simName}_${i} -c ${meshName} -m ${meshName}
    fi
done

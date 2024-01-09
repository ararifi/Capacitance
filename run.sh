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
cpus="4"

while getopts 's:m:c:n:' opt
do 
    case $opt in
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        n) cpus="$OPTARG"
    esac
done

if [ -z "$simName" ]; then
    echo "ERROR: No simulation name provided. Exiting..."
    exit 1
fi

configFile=""; meshFile=""
if [ ! -z "$meshName" ]; then
    
    meshFile="$dirMesh/$meshName.mesh"
    
    if [ ! -f "$meshFile" ]; then
        echo "Error: Mesh file $meshFile does not exist."
        exit 1
    fi
    
    if [ ! -f "$meshFile.logMesh" ]; then
        echo "Error: Mesh file $meshFile exists but no logMesh file found."
        exit 1
    fi

    configFile="$( cat "$meshFile.logMesh" | head -n 3 | tail -n 1 )"

else
    if [ -z "$configName" ]; then
        echo "Error: Config name does not exist."
        exit 1
    fi 

    configFile="$dirConfig/$configName.csv"
    if [ ! -f "$configFile" ]; then
        echo "Error: Config file $dirConfig/$configName.csv does not exist"
        exit 1
    fi

    echo "WARNING: Mesh file does not exist. Setting meshName as configName..."
    meshName="$configName"; meshFile="$dirMesh/$meshName.mesh"
    echo "Building mesh..."
    ./runMesh.sh -m "$meshName" -c "$configName"
fi


#------------------------------------------------------------
# RUN
#------------------------------------------------------------

# write out flags
outputFile="$dirOutput/$simName.log"
:> "$outputFile"
echo "$dirOutput" >> "$outputFile"
echo "$simName" >> "$outputFile"
echo "$configName" >> "$outputFile"
echo "$configFile" >> "$outputFile"
echo "$meshName" >> "$outputFile"
echo "$meshFile" >> "$outputFile"


# run simulation 
mpirun -np "$cpus" FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"

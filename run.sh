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

while getopts 's:m:c:o' opt
do 
    case $opt in
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
    esac
done

if [ -z "$simName" ]; then
    echo "ERROR: No simulation name provided. Exiting..."
    exit 1
fi

if [ -z "$configName" ]; then
    echo "WARNING: No mesh name provided. Setting simName as configName..."
    configName="$simName"
fi

configFile="$dirConfig/$configName.csv"
if [ ! -f "$configFile" ]; then
    echo "ERROR: No configuration file found. Exiting..."
    exit 1
fi

if [ -z "$meshName" ]; then
    echo "WARNING: No mesh name provided. Setting configName as meshName..."
    meshName="$configName"
fi


meshFile="$dirMesh/$meshName.mesh"; meshSFile="$dirMesh/$meshName.meshS"

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

# create default mesh if mesh file does not exist
if [ ! -f "$meshFile" ]; then
    echo "WARNING: No mesh file found. Building mesh..."
    ./runMesh.sh -m "$meshName" -c "$configName"
else 

mpirun -np 4 FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirCap" -n "$simName"
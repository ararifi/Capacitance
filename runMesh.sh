#!/bin/bash

#------------------------------------------------------------
# CONFIG 
#------------------------------------------------------------

source config.sh

#------------------------------------------------------------
# INPUT
#------------------------------------------------------------

# default values
meshNameIn=""
configName=""
onlyRelabel=false
rebuildMesh=true

while getopts 'm:c:r' opt
do 
    case $opt in
        m) meshNameIn="$OPTARG";;
        o) meshNameOut="$OPTARG";;
        c) configName="$OPTARG";;
        l) onlyRelabel=true;;
        f) rebuildMesh=false;;
    esac
done

if [ -z "$meshNameIn" ]; then
    echo "Error: No input mesh name provided"
    exit 1
fi

if [ -z "$meshNameOut" ]; then
    echo "WARNING: No output mesh name provided. Setting meshNameIn as meshNameOut..."
    meshNameOut="$meshNameIn"
fi

if [ -z "$configName" ]; then
    echo "WARNING: No config name provided. Setting meshNameIn as configName..."
    configName="$meshNameIn"
fi 

if [ ! -f "$configDir/$configName.csv" ]; then
    echo "Error: Config file $configDir/$configName.csv does not exist"
    exit 1
fi

meshFileIn="$dirMesh/$meshNameIn.mesh"; 

meshFileOut="$dirMesh/$meshNameOut.mesh"; meshSFile="$dirMesh/$meshNameOut.meshS" 
#------------------------------------------------------------
# SET SETTINGS
#------------------------------------------------------------

BUILD_MESHS=true; BUILD_MESH=true; RELABEL_MESH=true

if $onlyRelabel; then BUILD_MESHS=false; BUILD_MESH=false; fi

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

if [ -f "$meshFileOut" ]; then
    if $rebuildMesh; then
        echo "WARNING: Mesh file $meshFileOut already exists. Overwriting..."
    else
        echo "WARNING: Mesh file $meshFileOut already exists. Skipping..."
        exit 0
    fi
fi

if $BUILD_MESHS; then FreeFem++ buildMeshS.edp -c "$configFile" -o "$meshSFileOut" -i "$dirIco"; fi

if $BUILD_MESH; then FreeFem++ buildMesh.edp -c "$configFile" -m "$meshSFileIn" -o "$meshFileOut"; fi

if $RELABEL_MESH; then FreeFem++ relabelMesh.edp -c "$configFile" -m "$meshFileIn" -o "$meshFileOut"; fi

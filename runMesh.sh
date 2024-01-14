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

while getopts 'm:c:o:l' opt
do 
    case $opt in
        m) meshNameIn="$OPTARG";;
        o) meshNameOut="$OPTARG";;
        c) configName="$OPTARG";;
        l) onlyRelabel=true;;
#        f) rebuildMesh=false;;
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
    echo "Error: Config name does not exist."
    exit 1
fi 

configFile="$dirConfig/$configName.csv"
if [ ! -f "$configFile" ]; then
    echo "Error: Config file $dirConfig/$configName.csv does not exist"
    exit 1
fi

meshFileIn="$dirMesh/$meshNameIn.mesh"; meshFileOut="$dirMesh/$meshNameOut.mesh"; 

meshSFile="$dirMesh/$meshNameOut.meshS" 

#------------------------------------------------------------
# SET SETTINGS AND WRITE OUT DEPENDENCIES 
#------------------------------------------------------------

BUILD_MESHS=true; BUILD_MESH=true; RELABEL_MESH=true

if $onlyRelabel; then BUILD_MESHS=false; BUILD_MESH=false; echo "hi"; fi

logMesh="$dirMesh/$meshNameOut.logMesh"
:> "$logMesh"
echo "$meshFileIn" >> "$logMesh"
echo "$meshFileOut" >> "$logMesh"
echo "$configFile" >> "$logMesh"

#------------------------------------------------------------
# RUN
#------------------------------------------------------------

if $BUILD_MESHS; then FreeFem++ buildMeshS.edp -c "$configFile" -o "$meshSFile" -i "$dirIco"; fi

if $BUILD_MESH; then FreeFem++ buildMesh.edp -c "$configFile" -m "$meshSFile" -o "$meshFileOut"; fi

if $RELABEL_MESH; then FreeFem++ relabelMesh.edp -c "$configFile" -m "$meshFileIn" -o "$meshFileOut"; fi

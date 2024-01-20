#!/bin/bash

#SBATCH -J CapacityCoefficient
#SBATCH -A m2_jgu-binaryhpc 
#SBATCH -p parallel
#SBATCH -e ./data/slurmGlobal/slurm-%A-%a.err
#SBATCH -o ./data/slurmGlobal/slurm-%A-%a.out
#SBATCH -C skylake
#SBATCH --ntasks-per-node=32
#SBATCH --spread-job

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
mem="1000"

IS_CLUSTER=false

while getopts 'p:s:m:c:N:M:' opt
do 
    case $opt in
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        p) settingName="$OPTARG";;
        N) cpus="$OPTARG";;
        M) mem="$OPTARG";;
    esac
done

if [ -z "$simName" ]; then
    echo "ERROR: No simulation name provided. Exiting..."
    exit 1
fi

configFile=""; meshFile=""
if [ ! -z "$meshName" ]; then
    
    meshFile="$dirMesh/$meshName.mesh"

    logMeshFile="$dirMesh/$meshName.logMesh"
    
    if [ ! -f "$meshFile" ]; then
        echo "Error: Mesh file $meshFile does not exist."
        exit 1
    fi
    
    if [ ! -f "$logMeshFile" ]; then
        echo "Error: Mesh file $logMeshFile exists but no logMesh file found."
        exit 1
    fi

    configFile="$( cat "$logMeshFile" | head -n 3 | tail -n 1 )"

else
    if [ -z "$configName" ]; then
        echo "Error: Config name does not exist."
        exit 1
    fi 

    configFile="$dirConfig/$configName.csv"
    if [ ! -f "$configFile" ]; then
        echo "Error: Config file $configFile does not exist"
        exit 1
    fi

    echo "WARNING: Mesh file does not exist. Setting meshName as configName..."
    meshName="$configName"; meshFile="$dirMesh/$meshName.mesh"
    echo "Building mesh..."
    ./runMesh.sh -m "$meshName" -c "$configName" -p "$settingName"
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
echo "$settingName" >> "$outputFile"
echo "$settingFile" >> "$outputFile"


# run simulation 
ff="$( create_ff ${cpus} ${mem} ${dirSlurm} ${simName} )"

$ff laplacePeriodicSfc.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"

# jobID=""
# if [[ -z "$SLURM_ARRAY_JOB_ID" ]]; then
#     jobID="${SLURM_JOB_ID}_0"
# else
#     jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
# fi
# jobName="${simName}_${jobID}"
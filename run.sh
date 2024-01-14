#!/bin/bash

#SBATCH -J CapacityCoefficient
#SBATCH -A m2_jgu-binaryhpc 
#SBATCH -p parallel
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

while getopts 's:m:c:N:M:C' opt
do 
    case $opt in
        s) simName="$OPTARG";;
        m) meshName="$OPTARG";;
        c) configName="$OPTARG";;
        N) cpus="$OPTARG";;
        M) mem="$OPTARG";;
        C) IS_CLUSTER=true;;
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
if ! $IS_CLUSTER; then
    echo "Running simulation locally..."

    mpirun -np "$cpus" FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"
    # FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"
    exit 0
else
    echo "Running simulation on cluster..."
    
    jobID=""
    if [[ -z "$SLURM_ARRAY_JOB_ID" ]]; then
        jobID="${SLURM_JOB_ID}_0"
    else
        jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
    fi
    jobName="${simName}_${jobID}"

    srun --exact -u -c1 -n${cpus} --mem-per-cpu=${mem}M --mpi=pmi2 \
        -J ${jobName} -e "./${dirSlurm}/${jobName}.err" -o "./${dirSlurm}/${jobName}.out" \
        FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"
    exit 0
fi
        

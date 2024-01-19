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
meshNameIn=""
configName=""
onlyRelabel=false
rebuildMesh=true
IS_CLUSTER=false
mem=2700

while getopts 'm:c:o:lM:C' opt
do 
    case $opt in
        m) meshNameIn="$OPTARG";;
        o) meshNameOut="$OPTARG";;
        c) configName="$OPTARG";;
        l) onlyRelabel=true;;
        C) IS_CLUSTER=true;;
        M) mem="$OPTARG";;
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
    echo "Error: Config file $configFile does not exist"
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

create_run_ff_command() {
    local jobName="$1"

    if [ -z "$jobName" ]; then
        echo "srun --exact -u -c1 -n1 --mem-per-cpu=${mem}M --mpi=pmi2 \
        apptainer run $mogon_setup FreeFem++-mpi"
    else
        echo "srun --exact -u -c1 -n1 --mem-per-cpu=${mem}M --mpi=pmi2 \
            -J ${jobName} -e ./${dirSlurmMesh}/${jobName}.err -o ./${dirSlurmMesh}/${jobName}.out \
            apptainer run $mogon_setup FreeFem++-mpi"
    fi
}

# Usage

RUN_FF="FreeFem++"

jobName="mesh_${meshNameOut}"; if $IS_CLUSTER; then RUN_FF="$( create_run_ff_command "$jobName" )"; fi

if $BUILD_MESHS; then $RUN_FF buildMeshS.edp -c "$configFile" -o "$meshSFile" -i "$dirIco"; fi

if $BUILD_MESH; then $RUN_FF buildMesh.edp -c "$configFile" -m "$meshSFile" -o "$meshFileOut"; fi

jobName=""; if $IS_CLUSTER; then RUN_FF="$( create_run_ff_command "$jobName" )"; fi

if $RELABEL_MESH; then $RUN_FF relabelMesh.edp -c "$configFile" -m "$meshFileIn" -o "$meshFileOut"; fi


#srun --exact -u -c1 -n1 --mem-per-cpu=${mem}M --mpi=pmi2 \
#        -J ${jobName} -e "./${dirSlurm}/${jobName}.err" -o "./${dirSlurm}/${jobName}.out" \
#        apptainer run $mogon_setup FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"
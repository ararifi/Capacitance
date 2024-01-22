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
mem=2700

while getopts 'p:m:c:o:lM:' opt
do 
    case $opt in
        m) meshNameIn="$OPTARG";;
        o) meshNameOut="$OPTARG";;
        c) configName="$OPTARG";;
        p) settingName="$OPTARG";;
        l) onlyRelabel=true;;
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

settingFile="$dirSetting/$settingName.csv"
if [ ! -f "$settingFile" ]; then
    echo "Error: Setting file $settingFile does not exist"
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
echo "$settingFile" >> "$logMesh"

#------------------------------------------------------------
# RUN
#------------------------------------------------------------
# apptainer shell --no-home --bind /home/aarifi/prjs/Capacitance:/home/aarifi/Projects/Capacitance --pwd /home/aarifi/Projects/Capacitance /home/aarifi/cnts/ff

jobName="mesh_${meshNameOut}"
ff="$( create_ff "1" "${mem}" "${jobName}" "${dirSlurmMesh}" )"

if $BUILD_MESHS; then $ff buildMeshS.edp -c "$configFile" -o "$meshSFile" -i "$dirIco" -p "$settingFile"; fi

if $BUILD_MESH; then $ff buildMesh.edp -c "$configFile" -m "$meshSFile" -o "$meshFileOut" -p "$settingFile"; fi

jobName="mesh_relabel_${meshNameOut}"
ff="$( create_ff "1" "${mem}" "${jobName}" )"

if $RELABEL_MESH; then $ff relabelMesh.edp -c "$configFile" -m "$meshFileIn" -o "$meshFileOut"; fi


#srun --exact -u -c1 -n1 --mem-per-cpu=${mem}M --mpi=pmi2 \
#        -J ${jobName} -e "./${dirSlurm}/${jobName}.err" -o "./${dirSlurm}/${jobName}.out" \
#        apptainer run $mogon_setup FreeFem++-mpi laplace.edp -c "$configFile" -m "$meshFile" -o "$dirOutput" -n "$simName"
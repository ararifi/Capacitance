#!/bin/bash

#SBATCH -J CapacityCoefficient
#SBATCH -A m2_jgu-binaryhpc 
#SBATCH -p parallel
#SBATCH -e ./data/slurmGlobal/slurm-%A-%a.err
#SBATCH -o ./data/slurmGlobal/slurm-%A-%a.out
#SBATCH -C skylake
#SBATCH --ntasks-per-node=32
#SBATCH --spread-job

name="$1"
cmd="./runMesh.sh -m "$name" -c "$name" -p "$name" -M"2700" -i {}"
parallel ./runMesh.sh -m "$name" -c "$name" -p "$name" -M"5400" -i {} ::: "$( seq 1 4 )"
# sbatch -N1 -t30 parallel ./runMesh.sh -m "$name" -c "$name" -p "$name" -M"2700" -i {} ::: "$( seq 1 4 )"
# $( seq 1 2 13 )
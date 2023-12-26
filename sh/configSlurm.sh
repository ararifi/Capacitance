#!/bin/bash

# ----------------------------------------------------
# SET PATH AND DIRS
# ----------------------------------------------------

# script path
echo $SCRIPTPATH
[ ! -v $SCRIPTPATH ] && cd $SCRIPTPATH || ( echo "PARENT SCRIPTPATH NOT DEFINED"; exit )


# ----------------------------------------------------
# SETUP
# ----------------------------------------------------

# ----------------------------------------------------
# ---> SETUP: APPTAINER
APPTAINER_TMPDIR=/localscratch/${SLURM_JOB_ID}/

I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so


# ----------------------------------------------------
# ----> SETUP: NUMBER OF PARALLEL STEPS DEPENDED ON THE REQ MEMORY

NUM_CPUS="$( echo $SLURM_JOB_CPUS_PER_NODE | sed "s/,/\n/g" | sed "s/)//g" | sed -E "s/\(x[1-9]*//g" )"
MAX_NUM_CPUS_PER_NODE="$( echo $NUM_CPUS | awk '{print $1}' )"
for N in $( echo $NUM_CPUS ); do
    if [ "$N" -gt "$MAX_NUM_CPUS_PER_NODE" ]; then MAX_NUM_CPUS_PER_NODE="$N"; fi
done
MAX_NUM_CPUS_PER_NODE="$(( ${MAX_NUM_CPUS_PER_NODE}/2 ))"

# ----------------------------------------------------
# ---> SETUP: REQ MEMORY

MEM_PER_NODE="${SLURM_MEM_PER_NODE}"
if [ -z "$MEM_PER_NODE" ]; then
    MEM_PER_NODE="$( sacct -u aarifi -j ${SLURM_JOB_ID} --format="ReqMem" \
    | tail -n1 | grep -Po "\d*" )"
fi

MAX_MEM_PER_CPU="$(( ${MAX_NUM_CPUS_PER_NODE}/${MEM_PER_NODE} ))"

# if [ "$MEM_PER_MESH" -gt "$MEM_PER_NODE" ]; then MEM_PER_STEP=$MEM_PER_NODE; fi

# MEM_PER_CPU=$(( ${MEM_PER_STEP}/${TASKS_PER_STEP} ))

# ----------------------------------------------------
# ---> SETUP: NUMBER OF OVERALL CPUS

MAX_NUM_CPUS=$(( ${MAX_NUM_CPUS_PER_NODE}*${SLURM_NNODES} )) 

# ----------------------------------------------------
# ---> SETUP: JOB ID

jobID=""
if [[ -z "$SLURM_ARRAY_JOB_ID" ]]; then
  jobID="$SLURM_JOB_ID"
else
  jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
fi
#if [ -z $jobID ]; then jobID="${SLURM_JOB_ID}"; fi
#if [ -z $jobID ]; then jobID="${SLURM_JOBID}"; fi
#


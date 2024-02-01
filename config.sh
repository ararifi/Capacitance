# FIX PATH AND CREATE ALIAS FOR FREEFEM++
#------------------------------------------------------------

#SCRIPTPATH="/home/aarifi/Projects/Capacitance"
#export SCRIPTPATH

# --- !!! ---
#cd $SCRIPTPATH
# --- !!! ---

#------------------------------------------------------------
# DEFAULT
#------------------------------------------------------------

dirRoot="data"
dirOutput="$dirRoot/output"
dirMesh="$dirRoot/mesh"
dirConfig="$dirRoot/config"
dirSetting="$dirRoot/setting"
dirSlurm="$dirRoot/slurm"
dirSlurmMesh="$dirRoot/slurmMesh"

dirBase="base"
dirIco="pkgMesh/meshSicosphere/meshS/"

export IS_CLUSTER=false
if [ -n "$SLURM_JOB_ID" ] || [ -n "$SLURM_ARRAY_JOB_ID" ]; then
    IS_CLUSTER=true
fi

#------------------------------------------------------------
# FreeFem++
#------------------------------------------------------------

if [ -z "$PRJPATH" ]; then echo "PRJPATH is not set"; exit 1; fi
if [ -z "$FFAPTPATH" ]; then echo "FFAPTPATH is not set"; exit 1; fi


apt_setup="--env FF_INCLUDEPATH="$dirBase" --env FF_LOADPATH="$dirBase" --no-home --bind ${PRJPATH}/Capacitance:/home/aarifi/Projects/Capacitance --pwd /home/aarifi/Projects/Capacitance ${FFAPTPATH}"

create_srun_ff() {
    local ntasks="$1"
    local mem="$2"
    local jobName="$3"
    local slurmDir="$4"

    slurm_srun="srun --exact -c1 -n${ntasks} --mem-per-cpu=${mem}M --mpi=pmi2"
    slurm_info=""
    if [ -z "$slurmDir" ]; then
        slurm_info="-J ${jobName}"
    else
        slurm_info="-J ${jobName} -e ./${slurmDir}/${jobName}.err -o ./${slurmDir}/${jobName}.out"
    fi
    slurm_cmd="apptainer run $apt_setup FreeFem++-mpi"

    echo "${slurm_srun} ${slurm_info} ${slurm_cmd}"
}

create_mpirun_ff() {
    local ntasks="$1"
    echo "apptainer run $apt_setup /usr/freefem/ff-petsc/r/bin/mpirun -np $ntasks FreeFem++-mpi -wg"
}

create_ff() {
    local ntasks="$1"
    local mem="$2"
    local slurmDir="$3"
    local jobName="$4"

    if $IS_CLUSTER; then
        echo "$( create_srun_ff $ntasks $mem $slurmDir $jobName )"
    else
        echo "$( create_mpirun_ff $ntasks )"
    fi
}





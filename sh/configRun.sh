# PATHS TO INC: PARTICLE_DISTRIBUTION;;BASE;;OUTPUTNAME_CONFIGURATION
FF_INC="${pAPT_m}/ffpkg;;${pAPT_ffCap}/base;;${p_ffOutput};;${pAPT_m}/ffpkg/idp"

# PATHS TO LOAD: MESH_GENERATION_USER_DEFINED
FF_LOAD="${pAPT_m}/ffpkg/lib"

ffONE="$( APT_FF "srun -n1 -N1 -c1 --mem-per-cpu=${MEM_PER_CPU}M --exact --mpi=pmi2" $FF_INC $FF_LOAD "FreeFem++-mpi" )"

ffSTEP() {
    # ----- INPUT -----

    ffSTEP_JOBNAME=$1
    ffSTEP_FLAGS_FILE=$2
    ffSTEP_NTASKS=$3
    ffSTEP_MEM_PER_TASK=$4
    if [ -z "$3" ]; then ffSTEP_NTASKS=${TASKS_PER_STEP}; fi 
    #if [ -z "$4" ]; then ffSTEP_MEM_PER_TASK=${MEM_PER_CPU}; fi 

    # ----- PREPERATION -----
    # 
    ffSTEP_PREFIX=""
    if [ -z "${jobID}" ]; then
        ffSTEP_PREFIX=""
    elif [ -z $ffSTEP_MEM_PER_TASK ]; then 
        ffSTEP_PREFIX="srun \
        --exact -u -c1 -n${ffSTEP_NTASKS} --mpi=pmi2 \
        -J ${ffSTEP_JOBNAME} -e ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.err
        "
        #-o ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.out
        #"
    else
        ffSTEP_PREFIX="srun \
        --exact -u -c1 -n${ffSTEP_NTASKS} --mem-per-cpu=${ffSTEP_MEM_PER_TASK}M --mpi=pmi2 \
        -J ${ffSTEP_JOBNAME} -e ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.err
        "
        #-o ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.out
        #"
    fi
    # -J ${ffSTEP_JOBNAME} -e ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.err -o ./${outputFileDir}/logs/${ffSTEP_JOBNAME}.out"

    #ffSTEP_PREFIX="/cluster/easybuild/broadwell/software/impi/2021.9.0-intel-compilers-2023.1.0/mpi/2021.9.0/bin/mpirun"
 
    ffSTEP_CMD="FreeFem++-mpi ${ffSTEP_FLAGS_FILE}"


    # ----- RETURN -----

    ffSTEP_RUN="$( APT_FF "$ffSTEP_PREFIX" "$FF_INC" "$FF_LOAD" "$ffSTEP_CMD" )"
    
    $ffSTEP_RUN
}
#!/bin/bash

#SBATCH -J CapacityCoefficient
#SBATCH -A m2_jgu-binaryhpc 
#SBATCH -p parallel
#SBATCH -e ./jobOutput/slurm-%A-%a.err
#SBATCH -o ./jobOutput/slurm-%A-%a.out
#SBATCH -C skylake
#SBATCH --ntasks-per-node=32
#SBATCH --spread-job

# -----------------------------------------------------------------------
# PATH SCRIPT
# -----------------------------------------------------------------------

SCRIPTPATH="$p_m/ffCap"
export SCRIPTPATH

# --- !!! ---
cd $SCRIPTPATH
# --- !!! ---

export pAPT_ffCap="$pAPT_m/ffCap"

# -----------------------------------------------------------------------
# INPUT
# -----------------------------------------------------------------------

# SETUP: NUMBER OF TASKS $$ MEM PER STEP
export TASKS_PER_STEP="1"

export TIME_MAX=30

# MEM_PER_CPU in MB !!!
export MEM_PER_CPU=""

export NUM_CHUNK=""

# SIMULATION TYPE
export FF_FILENAME="";

export BLOCK_IND=1; 
export PAR_JOBS=1;

export TEST_RUN="false"

while getopts 'Tt:j:n:m:b:p:S:' opt
do 
    case $opt in
        
        T) TEST_RUN="true" ;;

        t) TIME_MAX=$OPTARG ;;

        # --- ALLOCATION ---
        
        j) PAR_JOBS=$OPTARG ;;
        n) TASKS_PER_STEP=$OPTARG ;;
        m) MEM_PER_CPU=$OPTARG ;;

        # --- SCRIPT-OPTIONS ---

        b) BLOCK_IND=$OPTARG ;;

        # --- FF-SIMULATION ---

        p) FF_FILENAME=$OPTARG ;;

        # --- SIM(OUTPUT)-DIR ---
        S) simDir=$OPTARG ;;

    esac
done

# -----------------------------------------------------------------------
# READ CONFIGS
# -----------------------------------------------------------------------
configLog="${simDir}/config.log"

if [ ! -f $configLog ]; then
    echo "ERROR: config.log does not exist!"
    exit 1
fi

# read config file
READ_CNT=1
export simName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export configName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export meshName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export outputDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export configDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export configFile="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export configFileDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export numIter="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export maxMeteor="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export numChunk="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export outputFileDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export outputName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export outputMeshDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export outputMeshFileDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export p_ffOutput="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export p_ffpkg="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export p_ffMesh="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export p_ffOutputMesh="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export dataDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export logDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

export slurmIDFile="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export simIDFile="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export meshIDFile="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export jobIDFile="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
export jobToDoIDFile="$( cat $configLog | sed -n ${READ_CNT}p )"


echo "INFO: simName=$simName"

# -----------------------------------------------------------------------
# SLURM-CONFIG
#
# Extract all the information from the slurm variables in order
# to get the necessary information to running the jobStep.
# -----------------------------------------------------------------------

export APPTAINER_TMPDIR=""
export I_MPI_PMI_LIBRARY=""
export MAX_NUM_CPUS_PER_NODE=""
export MAX_NUM_CPUS=""
export MAX_MEM_PER_CPU=""
export jobID=""

source ./configSlurm.sh

echo $jobID >> $slurmIDFile
# include job arrays compatibility

if [ ! -z $SLURM_ARRAY_TASK_ID ]; then
    BLOCK_IND=$SLURM_ARRAY_TASK_ID
else
    if [ $BLOCK_IND -eq -1 ]; then
        echo "ERROR: BLOCK_IND=-1"
        exit 1
    fi
fi

# -----------------------------------------------------------------------
# JOB-STEP CONFIG
#
# Here we create the needed directories for the output and run
# the configuration file in order to get the varfs
#
# User defined paths for ff is organized like the following figure.
#
#
#   FF-PATH ----> DEFAULT
#              I---> PATH
#              I---> .
#              ...
#           ----> ${p_m}
#              I---> ffpkg/
#              L---> ffpkg/lib/ 
#              I---> base/
#              I---> output/$simNameR/
# -----------------------------------------------------------------------

export FF_INC=""
export FF_LOAD=""
export ffONE=""

source ./configRun.sh

export -f ffSTEP;

# set jobstepName
jobstepName="${simName}"; export jobstepName

# -----------------------------------------------------------------------
# CHUNK-CONFIG
#
# Change arrInd if skip=true; all successed simulations are removed
# -----------------------------------------------------------------------

# read arrays from file
export strArrJob="$( cat $jobToDoIDFile )"; arrJob=( $strArrJob ); # CHANGED
export strArrSim="$( cat $simIDFile )"; arrSim=( $strArrSim );
export strArrMesh="$( cat $meshIDFile )"; arrMesh=( $strArrMesh );


arrLocalJob=()
lenArrJob="${#arrJob[@]}";
if [ "$lenArrJob" -eq 0 ]; then
    echo "ERROR: lenArrJob=0"
    exit 1
fi

szChunks="$(( ( $lenArrJob + $numChunk - 1) /$numChunk ))"
if [ "$szChunks" -eq 0 ]; then 
    szChunks=1
    if [ "$lenArrJob" -lt "$(( BLOCK_IND + 1 ))" ]; then
        echo "ERROR: lenArrJob<blockInd"
        exit 1
    fi
fi
startInd=$(( $BLOCK_IND * $szChunks ))
arrLocalJob+=( "${arrJob[@]:$startInd:$szChunks}" )
szArrLocalJob="${#arrLocalJob[@]}"
if [ "$szArrLocalJob" -eq 0 ]; then
    echo "ERROR: szArrLocalJob=0"
    exit 1
fi
echo "INFO: szArrLocalJob=$szArrLocalJob"

# -----------------------------------------------------------------------
# ITERATION
# -----------------------------------------------------------------------

timeOut() {
    
    recordFile_=$1
    jobStepName_ind_=$2
    
    # ----- SIGNAL_A -----

    SIGNAL_A=false;
    
    INTERVAL=1;
    while ! $SIGNAL_A; do   
        sleep $INTERVAL

        IND_NUM="$( cat $recordFile_ | grep -v ^$ | wc -l )"

        if [ "$IND_NUM" -eq 1 ]; then SIGNAL_A=true; fi

    done

    # ----- SINGAL_B -----

    SIGNAL_B=false

    INTERVAL=1; TIME_NOW=0
    if $SIGNAL_A; then
        while ! $SIGNAL_B; do

            if [ "$TIME_NOW" -gt "$TIME_MAX" ]; then break; fi

            sleep $INTERVAL

            IND_NUM="$( cat $recordFile_ | grep -v ^$ | wc -l )"
            
            if [ "$IND_NUM" -gt 1 ]; then SIGNAL_B=true; fi

            TIME_NOW="$(( $TIME_NOW+$INTERVAL ))"
        done
    fi

    rm -rf $recordFile_

    if ! $SIGNAL_B; then
        sacct -j"$jobID" --format="JobID, JobName%50" | grep -P "${jobStepName_ind_}" | awk '{print $1}' | xargs -i scancel {} &> /dev/null
        echo "TIME_OUT"
    else
        echo "DONE"
    fi

}
export -f timeOut

runSim() {
    
    job=$1
    
    MESH_BUILD="$( echo $FF_FILENAME | grep -P "build" )"

    if [ ! -z "$MESH_BUILD" ]; then
        if [ -f "${p_l}/Mesh/${meshName}.mesh${indMesh}" ]; then
             echo "INFO SKIP: ${p_l}/Mesh/${meshName}.mesh${indMesh} does not exist, skip $ind";
            return 
        fi
    else
        if [ -f "${outputFileDir}/data/cap.log$job" ]; then
            echo "INFO SKIP: cap.log${job} exists, skip $job";
            return 
        fi
    fi

    # --------------------------------- 
    # RUN SIMULATION
    # ---------------------------------

    jobStepName_ind="${jobstepName}_${job}"
    sim="$( echo $strArrSim | cut -d' ' -f$(( $job + 1 )) )"
    mesh="$( echo $strArrMesh | cut -d' ' -f$(( $job + 1 )) )"

    export NTASKS=$TASKS_PER_STEP
    # SCALING
    # if [ "$job" -gt 0 ]; then
    #     export NTASKS=$(( 4 * ( $job ) ))
    # else
    #     export NTASKS=1
    # fi


    # FOR TIME_OUT
    bgID=""
    recordFile="${outputFileDir}/data/record${job}.err";
    if [ -z $MESH_BUILD ]; then 
        
        :> $recordFile
        
        timeOut $recordFile $jobStepName_ind &
        bgID=$!
    fi

    # for scaling test add only the number of tasks at the end of the command
    ffSTEP "${jobStepName_ind}" "${FF_FILENAME}.edp \
        -S ${sim} -M ${mesh} -J ${job} \
        -simName ${simName} -simMaxInd ${numIter} -meshName ${meshName}" "$NTASKS" "$MEM_PER_CPU" | grep -P "^[^\[]" > ./${outputFileDir}/logs/${jobStepName_ind}.out

    # ---------------------------------

    if [ ! -z "$bgID" ]; then
        if [ "$( ps $bgID | awk '{print $3}' | tail -n1 )" = "S" ]; then
            kill $bgID
        fi
        rm -rf $recordFile

    fi


    if [ -z "$MESH_BUILD" ]; then 
        if [ ! -f "${outputFileDir}/data/cap.log$job" ]; then
            echo "INFO: INDEX $job NOT EVALUATED, SKIP" >&2
            return
        fi
    fi
    
    echo "INFO: INDEX $job EVALUATED" >&2

}
export -f runSim

if ! $TEST_RUN; then
    if [ -z "$PAR_JOBS" ]; then 
        parallel runSim ::: "${arrLocalJob[@]}"
    elif [ "$PAR_JOBS" -eq 1 ]; then
        for job in "${arrLocalJob[@]}"; do
            runSim $job
        done        
    else
        parallel -j${PAR_JOBS} runSim ::: "${arrLocalJob[@]}"
    fi
fi



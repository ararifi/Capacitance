#!/bin/bash



# script path

SCRIPTPATH="$p_m/ffCap"
export SCRIPTPATH

# --- !!! ---
cd $SCRIPTPATH
# --- !!! ---


# ----------------------------------------------------
#

# parallel ./epilogSim.sh ::: "CONVERGENCE7_P2Eff" "CONVERGENCE7_P2EffVol"

export SIMNAME="${1}"; if [ -z "$SIMNAME" ]; then echo "ERROR: no sim name given"; exit 1; fi
export OUTPUT_READ=true
export SLURM_READ=true
export NUM_CHUNKS=1
export CHUNK_INDEX=0
export MY_MESHNAME=""
export DIRECT=false

while getopts 'C:c:n:rsm:d' opt
do 
    case $opt in
        n) SIMNAME="$OPTARG";;
        C) NUM_CHUNKS="$OPTARG";;
        c) CHUNK_INDEX="$OPTARG";;
        o) OUTPUT_READ=false;;
        s) SLURM_READ=false;;
        m) MY_MESHNAME="$OPTARG";;
        d) DIRECT=true;;
    esac
done

simName=$SIMNAME
SIMNAME_OUTPUT=${CHUNK_INDEX}_${NUM_CHUNKS}_${simName}

# ----------------------------------------------------

#SIMDIR="$( cd ./output; ls ${SIMNAME} | grep -Po "${SIM_PREFIX}[^_]*" )"

simDir="output/$SIMNAME"

# check if dir exist
if [ ! -d $simDir ]; then echo "ERROR: $simDir doesn't exist"; exit 1; fi

cd $simDir
epilogOutputDir="epilogOutput"; if [ ! -d $epilogOutputDir ]; then mkdir "$epilogOutputDir"; fi    
SIMNAME_OUTPUT="$epilogOutputDir/${SIMNAME_OUTPUT}"

configLog="config.log"

# ----------------------------------------------------
# HELPER, CONFIG, STDVAR AND FUNTITONS
# ----------------------------------------------------

regFloat="[+-]?([0-9]*[.])?[0-9]+"

regSc="${regFloat}([eE]${regFloat})?"

function getKey(){
    #"$( cd logs/; ls | grep -Po ".*(?=\.jobID)" | sed "s/-/_/g" )"
    echo "$( cd "../${1}"; ls | grep -Po ".*(?=\.${2})" )"
}

function checkZeroSave() {
    if [ -z "$1" ]; then echo "NaN" >> "$2"; else echo "$1" >> "$2"; fi
}

function getVarLine() {
    sacct -u aarifi -j "${1}" --noconvert --format="JobName%60, ${2}%60" \
    | grep -P "${simName}" | grep -P "(?<=${simName}_)${3}[^\w]" | tail -n1
}

function createFiles() {
    # create files 
    arr="vars${1}[@]"
    for var in "${!arr}"; do 
        :> ${SIMNAME_OUTPUT}_${var}.log
    done
}

# 1: source; 2: apix; 3: ind
function writeData() {
    # write data
    IS_OK=1
    arr="${2}[@]"
    for var in "${!arr}"; do 
        dataFile="${1}/data/${var}.log${3}"
        if [ ! -f $dataFile ] || [ ! -s $dataFile ]; then
            echo "NaN" >> ${SIMNAME_OUTPUT}_${var}.log 
            echo "INFO: $dataFile doesn't exists or empty" >&2
            IS_OK=0
        else
            cat $dataFile >> ${SIMNAME_OUTPUT}_${var}.log
        fi
    done
    echo $IS_OK
}



# ----------------------------------------------------
# RERUN
# TODO: this is not working
# ----------------------------------------------------

simNameChild="$( pwd | grep -Po "[^/]*$" )"

# for the rerun problem
IS_RERUN=false
simName="$( echo $simNameChild | grep -Po "(?<=R-).*" )"
if [ -z $simName ]; then 
    simName=$simNameChild
else 
    # COPY ALL THE DATA FROM PARENT
    IS_RERUN=true
    for f in ../$simName/logs/*; do
        cp -n "$f" "logs/"
    done

    for f in ../$simName/data/*; do
        cp -n "$f" "data/"
    done

    parentDir="../$simName"

    # cp $parentDir/${simName}_ind.log ./
    # cp $parentDir/${simName}_meshInd.log ./
    cp $parentDir/*.jobID ./
fi


# ----------------------------------------------------
# SET AND LOAD VARIABLES
# ----------------------------------------------------

# NAMES AND IDs

READ_CNT=1
simName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
configName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))
meshName="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+10 ))

meshDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 )) 
outputMeshFileDir="$( cat $configLog | sed -n ${READ_CNT}p )"; READ_CNT=$(( $READ_CNT+1 ))

JobID="$( cat slurmID.log )"

# INDICIES

indArr=( $( cat "${simName}_indJob.log" ) )
indArrMesh=( $( cat "${simName}_indMesh.log" ) )

# get size of indArrMesh
sizeIndArrMesh=${#indArrMesh[@]}
sizeIndArr=${#indArr[@]}

# indicies of chunks
CHUNK_SIZE=$(( $sizeIndArr / $NUM_CHUNKS ))
CHUNK_START=$(( $CHUNK_INDEX * $CHUNK_SIZE ))
CHUNK_END=$(( $CHUNK_START + $CHUNK_SIZE - 1 ))
if [ "$CHUNK_END" -gt "$sizeIndArr" ]; then CHUNK_END=$(( $sizeIndArr-1 )); fi

# write chunk information in file
:> "${SIMNAME_OUTPUT}_chunk.log"
echo $CHUNK_INDEX >> "${SIMNAME_OUTPUT}_chunk.log"
echo $CHUNK_SIZE >> "${SIMNAME_OUTPUT}_chunk.log"
echo $CHUNK_START >> "${SIMNAME_OUTPUT}_chunk.log"
echo $CHUNK_END >> "${SIMNAME_OUTPUT}_chunk.log"

# ----------------------------------------------------
# MESH DATA
# ----------------------------------------------------

sourceMesh="../../$outputMeshFileDir"
if [ ! -z "$MY_MESHNAME" ]; then
    meshName=$MY_MESHNAME
fi

varsMsh=( "timMsh" "msh" "sph" "conf" "res" "h2s" "pos" "rad" )

createFiles "Msh"

jobLog=${SIMNAME_OUTPUT}_indNotOKMsh.joblog; :> $jobLog
maskFile=${SIMNAME_OUTPUT}_maskMsh.log; :> $maskFile


indArrSelect=("${indArr[@]:$CHUNK_START:$CHUNK_SIZE}")
for ind in "${indArrSelect[@]}"; do   
    
    meshInd="${indArrMesh[$ind]}"
    IS_OK="$( writeData $sourceMesh "varsMsh" $meshInd )"
    if [ "$IS_OK" -eq 0 ]; then
        echo "SKIP: not all mesh data @ ${meshInd}; reason doesn't exists"
        echo $meshInd >> $jobLog    
    fi
    echo $meshInd >> $maskFile
    echo $IS_OK >> $maskFile    
done

# ----------------------------------------------------
# SIM DATA
# ----------------------------------------------------

sourceSim="../$simName"

simOK=()

vars=( "cap" "sfc" "tim" "ntasks" )

vars2=( "effCap" "effCapSfc" )

createFiles ""

createFiles "2"

jobLog=${SIMNAME_OUTPUT}_indNotOK.joblog; :> $jobLog
maskFile=${SIMNAME_OUTPUT}_mask.log; :> $maskFile

indArrSelect=( "${indArr[@]:$CHUNK_START:$CHUNK_SIZE}" )
for ind in "${indArrSelect[@]}"; do

    IS_OK="$( writeData $sourceSim "vars" $ind )"
    if [ "$IS_OK" -eq 0 ]; then 
        echo "SKIP: not all sim data @ ${ind}; reason doesn't exists or empty"
        echo $ind >> $jobLog  
    fi
    echo $ind >> $maskFile
    echo $IS_OK >> $maskFile

    simOK+=($IS_OK)

    writeData $sourceSim "vars2" $ind &>/dev/null;    
done

# ----------------------------------------------------
# STATISTICS
# ----------------------------------------------------
#
varsSlurm=( "ElapsedRAW" "CPUTimeRAW" "MaxRSS" "AveRSS" )
varsSlurm2=( "NTasks")

varsErrSlurm=( "ExitCode" )

statisFile="${SIMNAME_OUTPUT}_statis.log"; :>${statisFile};
statisFile2="${SIMNAME_OUTPUT}_statis2.log"; :>${statisFile2};

errFile="${SIMNAME_OUTPUT}_err.log"; :>${errFile}

# a file where all the indicies are stored
indArrSelect=( "${indArr[@]:$CHUNK_START:$CHUNK_SIZE}" )
CNT=0; 

for ind in "${indArrSelect[@]}"
do 
    meshInd="${indArrMesh[$ind]}"
    checkMesh=true;
    
    if [ "${simOK[CNT]}" -eq 0 ]; then
        echo "SKIP: corrupt data @ ${ind}"
        #CNT=$(( $CNT+1 ))
        checkMesh=false
    fi
    # ----------------------------------------------------
    # GET INFOS FROM MESH JOB OUTPUT
    # ----------------------------------------------------


    # Tetgen memory consumption   
    match=""
    if $OUTPUT_READ && $checkMesh ; then
        match="$(  cat "$sourceMesh/logs/${meshName}_${meshInd}.out" | \
            grep -Po "(?<=Approximate total used memory \(bytes\):)\s*\K[\,\d]*" | sed "s/,//g" | tail -n1 )"
    else
        match=""
    fi
    checkZeroSave "$match" "$statisFile"
    
    match=""
    # FreeFem execution time
    if $OUTPUT_READ && $checkMesh ; then
        match="$( cat "$sourceMesh/logs/${meshName}_${meshInd}.out" | \
            grep -P "times:" | grep -P "mpirank:0" | grep -Po "(?<=execution\s)$regSc" | tail -n1 )"
    else
        match=""
    fi
    checkZeroSave "$match" "$statisFile"
    
    # Slurm statitistics
    match=""
    for svar in "${varsSlurm[@]}"; do
        
        if $SLURM_READ && $checkMesh ; then
            for jobID in $( echo $JobID ); do
                match="$( getVarLine "${jobID}" "${svar}" "${ind}" \
                    | grep -Po "${regFloat}\s*(?=$)" )"
                if [ ! -z $match ]; then break; fi
            done
        else 
            match=""
        fi
        checkZeroSave "$match" "$statisFile"
        match=""
    done
    
    # Slurm statitistics 2
    match=""
    for svar in "${varsSlurm2[@]}"; do
        if $SLURM_READ && $checkMesh ; then
            for jobID in $( echo $JobID ); do
                match="$( getVarLine "${jobID}" "${svar}" "${ind}" \
                    | grep -Po "[\d\:]*\s*(?=$)" | sed s/":"/"\n"/g | grep -Po "\d*" )"
                if [ ! -z $match ]; then break; fi
            done
        else 
            match=""
        fi
        checkZeroSave "$match" "$statisFile2"
        match=""
    done

    # Slurm error statitistics
    matchLine=""
    for jobID in $( echo $jobID ); do
        if $SLURM_READ && $checkMesh ; then
            matchLine="$( getVarLine "${jobID}" "ExitCode" "${ind}" )"
            if [ ! -z "$matchLine" ]; then 
                echo $matchLine | grep -Po "[\d\:]*\s*(?=$)" \
                | sed s/":"/"\n"/g | grep -Po "\d*" | xargs -i echo -e {}  >> $errFile
                break
            fi
        else
            matchLine=""
        fi
    done
    if [ -z "$matchLine" ]; then 
        echo -e "NaN\nNaN" >> $errFile
    fi
    CNT=$(( $CNT+1 ))
done


# ----------------------------------------------------
# RENAME
# ----------------------------------------------------

if $IS_RERUN; then
    ls ../ | grep -P "(?<!(R-))$simName" | xargs -i mv "../{}" "../O-{}"
    mv ../$simNameChild ../$simName
fi


#-----------------------------------------------------

# this file should be activated in the output directory of the scenario
#
# in output path run 
# OVERWRITE_EPILOG=false; 
: <<'END'
EPILOG_OVERWRITE=true
SIM_PREFIX="RND32"
for dir in ${SIM_PREFIX}* ; do 
    echo "$( cd "$dir/"; if [ ! -f "${dir}_mask.log" ] || $EPILOG_OVERWRITE ; then ../../epilogSim.sh; fi )"
done
END

if "$DIRECT"; then $SCRIPTPATH/epilogZip.sh -n $SIMNAME; fi

echo "BYE $CHUNK_INDEX OF $NUM_CHUNKS COMPLETED $CHUNK_SIZE DATA"; exit 0;

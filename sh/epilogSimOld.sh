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

SIMNAME="${1}"



# ----------------------------------------------------

#SIMDIR="$( cd ./output; ls ${SIMNAME} | grep -Po "${SIM_PREFIX}[^_]*" )"
cd output/$SIMNAME


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
        :> ${simName}_${var}.log
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
            echo "NaN" >> ${simName}_${var}.log   
            IS_OK=0
        else
            cat $dataFile >> ${simName}_${var}.log
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

jobID="$( getKey "${simName}" "jobID" )"

configName="$( getKey "${simName}" "configName" )"

meshName="$( getKey "${simName}" "meshName" )"
simName="$( getKey "${simName}" "outputName" )"


# INDICIES

mapfile -t indArr <<< "$( cat "${simName}_indJob.log" )"

mapfile -t indArrMesh <<< "$( cat "${simName}_indMesh.log" )"

# get size of indArrMesh
sizeIndArrMesh=${#indArrMesh[@]}
sizeIndArr=${#indArr[@]}

# ----------------------------------------------------
# MESH DATA
# ----------------------------------------------------

sourceMesh="../../outputMesh/$meshName"
if [ ! -z "$2" ]; then
    sourceMesh="../../$2/$meshName"
fi

varsMsh=( "timMsh" "msh" "sph" "conf" "res" "h2s" "pos" "rad" )

createFiles "Msh"

jobLog=${simName}_indNotOKMsh.joblog; :> $jobLog
maskFile=${simName}_maskMsh.log; :> $maskFile
for ind in "${indArr[@]}"; do
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

vars=( "cap" "sfc" "tim" "ntasks" )

vars2=( "effCap" )

createFiles ""

createFiles "2"

jobLog=${simName}_indNotOK.joblog; :> $jobLog
maskFile=${simName}_mask.log; :> $maskFile
for ind in "${indArr[@]}"; do
    IS_OK="$( writeData $sourceSim "vars" $ind )"
    if [ "$IS_OK" -eq 0 ]; then 
        echo "SKIP: not all sim data @ ${ind}; reason doesn't exists"
        echo $ind >> $jobLog  
    fi
    echo $ind >> $maskFile
    echo $IS_OK >> $maskFile

    writeData $sourceSim "vars2" $ind &>/dev/null;
done

# ----------------------------------------------------
# STATISTICS
# ----------------------------------------------------
#
varsSlurm=( "ElapsedRAW" "CPUTimeRAW" "MaxRSS" "AveRSS" )
varsSlurm2=( "NTasks")

varsErrSlurm=( "ExitCode" )

statisFile="${simName}_statis.log"; :>${statisFile};
statisFile2="${simName}_statis2.log"; :>${statisFile2};

errFile="${simName}_err.log"; :>${errFile}

for ind in "${indArr[@]}"
do 

    # ----------------------------------------------------
    # GET INFOS FROM MESH JOB OUTPUT
    # ----------------------------------------------------

    meshInd="${indArrMesh[$ind]}"

    # Tetgen memory consumption   
    match="$(  cat "$sourceMesh/logs/${meshName}Mesh_${meshInd}.out" | \
        grep -Po "(?<=Approximate total used memory \(bytes\):)\s*\K[\,\d]*" | sed "s/,//g" | tail -n1 )"
    checkZeroSave "$match" "$statisFile"
    match=""

    # FreeFem execution time
    match="$( cat logs/${simName}_${ind}.out | grep -P "times:" | grep -P "mpirank:0" | grep -Po "(?<=execution\s)$regSc" | tail -n1 )"
    checkZeroSave "$match" "$statisFile"
    match=""
    
    # Slurm statitistics
    for svar in "${varsSlurm[@]}"; do
        for jobID in $( echo $JobID ); do
            match="$( getVarLine "${jobID}" "${svar}" "${ind}" \
                | grep -Po "${regFloat}\s*(?=$)" )"
            if [ ! -z $match ]; then break; fi
        done
        checkZeroSave "$match" "$statisFile"
        match=""
    done
    
    # Slurm statitistics 2
    for svar in "${varsSlurm2[@]}"; do
        for jobID in $( echo $jobID ); do
            match="$( getVarLine "${jobID}" "${svar}" "${ind}" \
                | grep -Po "[\d\:]*\s*(?=$)" | sed s/":"/"\n"/g | grep -Po "\d*" )"
            if [ ! -z $match ]; then break; fi
        done
        checkZeroSave "$match" "$statisFile2"
        match=""
    done

    # Slurm error statitistics
    matchLine=""
    for jobID in $( echo $jobID ); do
        matchLine="$( getVarLine "${jobID}" "ExitCode" "${ind}" )"
        if [ ! -z "$matchLine" ]; then 
            echo $matchLine | grep -Po "[\d\:]*\s*(?=$)" \
            | sed s/":"/"\n"/g | grep -Po "\d*" | xargs -i echo -e {}  >> $errFile
            break
        fi
    done
    if [ -z "$matchLine" ]; then 
        echo -e "NaN\nNaN" >> $errFile
    fi
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

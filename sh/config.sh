#!/bin/bash


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
# FUNCTIONS
# -----------------------------------------------------------------------

function arrTOstr(){
    ARRAY="$1[@]"; ARRAY=( ${!ARRAY} )
    STRING=""
    for i in "${ARRAY[@]}"; do
        STRING+="$i "
    done
    echo $STRING
}

function getInd(){
    prefix="$1"; arrInd=()

    IDname="ID${prefix}"
    if [ ! -z "${!IDname}" ]; then 
        for i in $( seq 1 "$numIter" ); do
            arrInd+=("${!IDname}")
        done
    else
        arrInd=($( seq 0 "$(( $numIter-1 ))"))
    fi

    strArrInd=$( arrTOstr "arrInd" )

    echo $strArrInd
}

function writeInd(){

    prefix=$1; strArrInd=$2

    # transfer indices to file    
    indFile="${outputFileDir}/${outputName}_ind${prefix}.log"
    :> "$indFile"

    # save in one line
    echo "$strArrInd" >> "$indFile"

    echo $indFile
}

# -----------------------------------------------------------------------
# INPUT
# -----------------------------------------------------------------------

# SETUP: NUMBER OF TASKS $$ MEM PER STEP
export IS_SKIP="SIM"

export numChunk="1"

export SINGLE="false"

# INDEX WITHIN CONFIG FILE
export simName=""; export configName=""; export meshName="";

# MESH CHOOSE
export IDMesh=""; export IDSim="";

# RESTART
export REINIT=false

export outputDir="output"; 
export meshDir="outputMesh";
export configDir="config"

while getopts 'sk:ri:j:n:S:F:M:o:m:c:' opt
do 
    case $opt in
        
        # --- SCRIPT-OPTIONS ---
        k) IS_SKIP=$OPTARG ;; # MESH OR SIM
        r) REINIT=true ;;

        # --- FF-SIMULATION ---
        i) IDMesh=$OPTARG ;;
        j) IDSim=$OPTARG ;;
        n) numChunk=$OPTARG ;;
        s) SINGLE=true ;;

        S) simName=$OPTARG ;;
        F) configName=$OPTARG ;;
        M) meshName=$OPTARG ;;

        # --- DIR ---
        o) outputDir=$OPTARG ;;
        m) meshDir=$OPTARG ;;
        c) configDir=$OPTARG ;;

    esac
done

if [ -z $simName ]; then simName=$configName; fi
export outputName=$simName

# -----------------------------------------------------------------------
# DIR CONFIG
# -----------------------------------------------------------------------


# --- SET CONFIGS ---
configFile="$( ls config | grep -P "${configName}(?=_)" | grep -P "\.edp" | grep -P "^[^_]+" )"
echo $configFile

configFileDir="$configDir/$configFile"

numIter="$( echo $configFile | grep -Po "[^_]*(?=(_|\.))" | tail -n 1 )"; export numIter
if $SINGLE; then numIter="1"; fi

maxMeteor="$( echo $configFile | grep -Po "[^_]*(?=(_|\.))" | tail -n 2 | head -n 1 )"; export maxMeteor

# --- SET OUTPUT ---
outputFileDir="$outputDir/$outputName"

if [ -z "$outputName" ]; then
    echo "no configs, exit..."
    exit 1
fi

# --- SET APT-PATHS ---
p_ffOutput="${pAPT_ffCap}/${outputFileDir}"
p_ffpkg="${pAPT_m}/ffpkg"

# --- SET OUTPUT OF MESH ---
outputMeshDir=${meshDir}
outputMeshFileDir="${outputMeshDir}/${meshName}";
p_ffMesh="${pAPT_l}/Mesh"
p_ffOutputMesh="${pAPT_ffCap}/${outputMeshDir}/${meshName}"

dataDir="${outputFileDir}/data"; 
logDir="${outputFileDir}/logs"; 

configLog="${outputFileDir}/config.log"


# -----------------------------------------------------------------------
# REINIT
# -----------------------------------------------------------------------

if $REINIT; then
    if [ ! -f $configLog ]; then
        echo "ERROR: $configLog does not exist, exit..."
        exit 1
    fi

    jobToDoFile=( $( cat $configLog | tail -n 1 ) )
    arrJobOld=( $( cat $jobToDoFile ) ); arrJob=()

    meshFile=( $( cat $configLog | tail -n 3 | head -n 1 ) )
    arrMesh=( $( cat $meshFile ) )

    if [ "$IS_SKIP" == "SIM" ]; then
        for ind in "${arrJobOld[@]}"; do
            
            indMesh="${arrMesh[$ind]}"      
            
            if [ -f "${outputFileDir}/data/cap.log$ind" ]; then
                echo "INFO SKIP: cap.log${ind} exists, skip $ind";

            elif [ ! -f "${p_l}/Mesh/${meshName}.mesh${indMesh}" ]; then
                echo "INFO SKIP: ${p_l}/Mesh/${meshName}.mesh${indMesh} does not exist, skip $ind";
            else
                arrJob+=( "$ind" )
            fi
        done
    elif [ "$IS_SKIP" == "MESH" ]; then
        for ind in "${arrJobOld[@]}"; do
            
            indMesh="${arrMesh[$ind]}"        
            
            if [ -f "${p_l}/Mesh/${meshName}.mesh${indMesh}" ]; then
                echo "INFO SKIP: ${p_l}/Mesh/${meshName}.mesh${indMesh} does not exist, skip $ind";
            else
                arrJob+=( "$ind" )
            fi
        done
    else
        arrJob=( "${arrJobOld[@]}" )
    fi

    if [ ${#arrJob[@]} -eq 0 ]; then
        echo "INFO SKIP: no jobs"
        exit 1
    fi

    echo "INFO: REINIT: ${#arrJob[@]} jobs"
    strArrJobToDo=$( arrTOstr "arrJob" );
    echo $strArrJobToDo
    jobToDoIDFile=$( writeInd "JobToDo" "$strArrJobToDo" )

    exit 1    
fi



# -----------------------------------------------------------------------
# CREATE DIR
# -----------------------------------------------------------------------

mkdir ${outputFileDir}; mkdir $dataDir; mkdir $logDir; 


# -----------------------------------------------------------------------
# FF-CONFIG
# -----------------------------------------------------------------------


cp ${configFileDir} ${outputFileDir}/simConfig.idp

cp ${configFileDir} ./configTemp/

./config_bMacro.sh "$outputFileDir"


# -----------------------------------------------------------------------
# ID- && INDICES-CONFIG
#
# meshInd = index of mesh
# simInd = index within mesh building
# jobInd = index for the job
# -----------------------------------------------------------------------

# IDs

slurmIDFile="${outputFileDir}/slurmID.log"
:> $slurmIDFile

# INDICES

strArrSim=$( getInd "Sim" ); arrSim=( $strArrSim )
simIDFile=$( writeInd "Sim" "$strArrSim" )

strArrMesh=$( getInd "Mesh" ); arrMesh=( $strArrMesh )
meshIDFile=$( writeInd "Mesh" "$strArrMesh" )

strArrJob=$( getInd "Job" ); arrJob=( $strArrJob )
jobIDFile=$( writeInd "Job" "$strArrJob" )

arrJobOld=( "${arrJob[@]}" ); arrJob=()

if [ "$IS_SKIP" == "SIM" ]; then
    for ind in "${arrJobOld[@]}"; do
        
        indMesh="${arrMesh[$ind]}"        
        
        if [ -f "${outputFileDir}/data/cap.log$ind" ]; then
            echo "INFO SKIP: cap.log${ind} exists, skip $ind";

        elif [ ! -f "${p_l}/Mesh/${meshName}.mesh${indMesh}" ]; then
            echo "INFO SKIP: ${p_l}/Mesh/${meshName}.mesh${indMesh} does not exist, skip $ind";
        else
            arrJob+=( "$ind" )
        fi
    done
elif [ "$IS_SKIP" == "MESH" ]; then
    for ind in "${arrJobOld[@]}"; do
        
        indMesh="${arrMesh[$ind]}"        
        
        if [ -f "${p_l}/Mesh/${meshName}.mesh${indMesh}" ]; then
            echo "INFO SKIP: ${p_l}/Mesh/${meshName}.mesh${indMesh} does not exist, skip $ind";
        else
            arrJob+=( "$ind" )
        fi
    done
else
    arrJob=( "${arrJobOld[@]}" )
fi

strArrJobToDo=$( arrTOstr "arrJob" );
jobToDoIDFile=$( writeInd "JobToDo" "$strArrJobToDo" )


# -----------------------------------------------------------------------
# ACTION
# -----------------------------------------------------------------------

# write to file
:> "${configLog}"

echo $simName >> $configLog
echo $configName >> $configLog
echo $meshName >> $configLog

echo $outputDir >> $configLog
echo $configDir >> $configLog
echo $configFile >> $configLog
echo $configFileDir >> $configLog

echo $numIter >> $configLog
echo $maxMeteor >> $configLog
echo $numChunk >> $configLog

echo $outputFileDir >> $configLog
echo $outputName >> $configLog

echo $outputMeshDir >> $configLog
echo $outputMeshFileDir >> $configLog

echo $p_ffOutput >> $configLog
echo $p_ffpkg >> $configLog
echo $p_ffMesh >> $configLog
echo $p_ffOutputMesh >> $configLog

echo $dataDir >> $configLog
echo $logDir >> $configLog

echo $slurmIDFile >> $configLog
echo $simIDFile >> $configLog
echo $meshIDFile >> $configLog
echo $jobIDFile >> $configLog
echo $jobToDoIDFile >> $configLog

#!/bin/bash

TIME_MAX=60


checkSignal() {
    local TIME_MAX="$1"
    local recordFile="$2"

    SIGNAL=false
    INTERVAL=1; TIME_NOW=0
    while ! $SIGNAL; do
        sleep $INTERVAL
        if [ -f "$recordFile" ]; then SIGNAL=true; fi
        TIME_NOW="$(( $TIME_NOW+$INTERVAL ))"
        # make output every 10 seconds
        if [ "$(( $TIME_NOW%10 ))" -eq 0 ]; then echo "INFO: waited $TIME_NOW seconds for $recordFile" >&2; fi

        if [ "$TIME_NOW" -gt "$TIME_MAX" ]; then break; fi
    done

    echo $SIGNAL
}
export -f checkSignal


timeOut() {
    local dirOutput="$1"
    local simName="$2"
    local jobStepName="$3"

    local recordFileStart="$dirOutput/${simName}_START.signal"
    local recordFileA="$dirOutput/${simName}_A.signal"
    local recordFileB="$dirOutput/${simName}_B.signal"

    # ----- SIGNALS -----


    SIGNAL_START="$( checkSignal 1200 "$recordFileStart" )"
    
    SIGNAL_A=false
    if $SIGNAL_START; then SIGNAL_A="$( checkSignal 180 "$recordFileA" )"; fi

    SIGNAL_B=false
    if $SIGNAL_A; then SIGNAL_B="$( checkSignal 60 "$recordFileB" )"; fi

    if ! $SIGNAL_B; then
        jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
        if [[ -z "${SLURM_ARRAY_JOB_ID}" ]]; then
            jobID="$SLURM_JOB_ID"
        fi
        #scancel --name $jobStepName
        echo "INFO: time out, kill job $jobStepName under jobID $jobID" >&2
        sacct -j"$jobID" --format="JobID%50, JobName%50" | grep -P "${jobStepName}" | awk '{print $1}' | xargs -i scancel {} &> /dev/null
    else
        echo "INFO: DDM done properly " >&2
    fi

    rm -rf "$recordFileStart"
    rm -rf "$recordFileA"
    rm -rf "$recordFileB"
}
export -f timeOut


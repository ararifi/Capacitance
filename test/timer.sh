#!/bin/bash

notificationDir="../data/output"
TIME_MAX=5

timeOut() {
        
    local simName="$1"
    local jobStepName="$2"

    local recordFileStart="$notificationDir/$simName.start"
    local recordFileSuccess="$notificationDir/$simName.success"

    # ----- SIGNAL_A -----

    SIGNAL_A=false;
    
    INTERVAL=1;
    while ! $SIGNAL_A; do   
        sleep $INTERVAL
        # check if $recordFile exist 
        if [ -f "$recordFileStart" ]; then SIGNAL_A=true; fi
    done
    ls -l "$recordFileStart"

    # ----- SINGAL_B -----

    SIGNAL_B=false

    INTERVAL=1; TIME_NOW=0
    if $SIGNAL_A; then
        while ! $SIGNAL_B; do

            if [ "$TIME_NOW" -gt "$TIME_MAX" ]; then break; fi

            sleep $INTERVAL

            if [ -f "$recordFileSuccess"  ]; then SIGNAL_B=true; fi

            TIME_NOW="$(( $TIME_NOW+$INTERVAL ))"

        done
    fi


    if ! $SIGNAL_B; then
        jobID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
        if [[ -z "${SLURM_ARRAY_JOB_ID}" ]]; then
            jobID="$SLURM_JOB_ID"
        fi
        #scancel --name $jobStepName
        echo "INFO: time out, kill job $jobStepName under jobID $jobID"
        sacct -j"$jobID" --format="JobID, JobName%50" | grep -P "${jobStepName}" | awk '{print $1}' | xargs -i scancel {} &> /dev/null
    else
        echo "INFO: done"
    fi
    rm -rf "$recordFileStart"
    rm -rf "$recordFileSuccess"
}
export -f timeOut

export simName="test_timer"

export recordFileStart="$notificationDir/$simName.start"
export recordFileSuccess="$notificationDir/$simName.success"

timeOut $simName $simName &
bgID=$!
srun -J"$simName" --exclusive -n"1" --mem "2700" test.sh $simName $simName;
wait $bgID


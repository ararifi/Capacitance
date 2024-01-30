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
        if [ ! -f "$recordFileStart" ]; then SIGNAL_A=true; fi
    done

    rm -rf $recordFileStart

    # ----- SINGAL_B -----

    SIGNAL_B=false

    INTERVAL=1; TIME_NOW=0
    if $SIGNAL_A; then
        while ! $SIGNAL_B; do

            if [ "$TIME_NOW" -gt "$TIME_MAX" ]; then break; fi

            sleep $INTERVAL

            if [ ! -f "$recordFileSuccess"  ]; then SIGNAL_B=true; fi

            TIME_NOW="$(( $TIME_NOW+$INTERVAL ))"
        done
    fi

    rm -rf $recordFileSuccess

    if ! $SIGNAL_B; then
        scancel -n"$jobStepName" --me
        echo "TIME_OUT"
    else
        echo "DONE"
    fi
}
export -f timeOut

export simName="test_timer"

export recordFileStart="$notificationDir/$simName.start"
export recordFileSuccess="$notificationDir/$simName.success"

timeOut $simName $simName &

srun -J $simName -n"1" --mem"2700" test.sh $simName $simName;



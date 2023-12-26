#!/bin/bash

# script path

SCRIPTPATH="$p_m/ffCap"
export SCRIPTPATH

# --- !!! ---
cd $SCRIPTPATH
# --- !!! ---


# ----------------------------------------------------

export SIMNAME="${1}"; if [ -z "$SIMNAME" ]; then echo "ERROR: no sim name given"; exit 1; fi

while getopts 'n:' opt
do 
    case $opt in
        n) SIMNAME="$OPTARG";;
    esac
done

# ----------------------------------------------------
# DIR 
# ----------------------------------------------------

OUT="./output/${SIMNAME}"
EPOOUT="./output/${SIMNAME}/epilogOutput"

# ----------------------------------------------------
# ZIP
# ----------------------------------------------------

# Step 2: Extract and collect all distinct 'x' values from the log file names.
distinct_x_values="$( find $EPOOUT -type f -exec basename {} \; | cut -d '_' -f 4 | sort -u )"

# Step 3: Iterate over the distinct 'x' values and combine the corresponding log files.
echo "START ZIP"
for x in $distinct_x_values; do


  # Create an empty x.log file or overwrite an existing one for each 'x' value.
  
  OUT_FILE="${OUT}/${SIMNAME}_${x}"
  :>"${OUT_FILE}"
  
  # Loop through the log files for the current 'x' value and append their content to x.log.
  log_files="$( ls "${EPOOUT}/"*"${x}" | sort )"

  for log_file in $log_files; do
    if [ -e "$log_file" ]; then cat "$log_file" >> "${OUT_FILE}"; fi
  done
done
echo "END ZIP"; exit 0
# GET ALL DIFFERENT PATTERN BY EXTRACTING FROM EPOOUT DIR FILES THE FIRST WORDS BEFORE "_"
# AND THEN SORT AND REMOVE DUPLICATES



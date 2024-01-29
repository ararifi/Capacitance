get_configNames() {

    local dirConfig=$1
    local configName=$2

    # get the config names without suffix
    configNames="$( find $dirConfig -maxdepth 1 -name "${configName}*" -type f -exec basename {} \; | sed 's/\.[^.]*$//' )"
    echo $configNames
}

extract_indices() {

    local configNames=$1

    # extract the config names without suffix
    indices="$( echo "$configNames" | grep -oP '(?<=_)\d+(?=$)' | sort -n )"
    echo $indices
}

get_index_config() {

    local indices_config=$3
    local index=$2

    index_config="$( echo "$indices_config" | head -n $(( index + 1 )) | tail -n 1 )"

    echo $index_config
}

run_by_index() {

    local script=$2

    # run the simulation by index
    echo "$script -s "${simName}_${index}" -c "${configName}_${index}" -m "${meshName}_${index}" -N "$cpus" -M "$mem" -C"
}
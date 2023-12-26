#------------------------------------------------------------
# PATHS 
#------------------------------------------------------------

SCRIPTPATH="$p_m/ffCap"
export SCRIPTPATH

# --- !!! ---
cd $SCRIPTPATH
# --- !!! ---

configDir="config"


#------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------

# function that exit script if file is not in configDir
function checkFile {
    if [ ! -f "$configDir/$1" ]; then
        echo "File $1 does not exist in $configDir"
        exit 1
    fi
}


#------------------------------------------------------------
# SLURM EXECUTION
#------------------------------------------------------------

SIM_PREFIX="FEMares"
export FF_VERBOSITY=1
CONFIG_NAMES="$( cd ./config; ls ${SIM_PREFIX}* | grep -Po "${SIM_PREFIX}[^_]*" )"
for CONFIG_NAME in $CONFIG_NAMES; do
    MESH_NAME="${CONFIG_NAME}"

    #sbatch -N1 -t10 ./slurmJobMesh.sh -n"1" -m"11000" -c"5" -p"Mesh" -F"${CONFIG_NAME}" -M"${CONFIG_NAME}"
    
    sbatch -N2 -t45 ./slurmJobMesh.sh -k -n"1" -m"2700" -c"540" -p"MeshS" -F"${CONFIG_NAME}" -M"${CONFIG_NAME}SFC"
done



: <<'END'
" COMMENT "
END

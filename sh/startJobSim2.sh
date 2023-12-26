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

# add flags 





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

#1, CHUNKS=18 SIM_PREFIX="RND2CC2048"


SIM_PREFIX="$1"
ELEMENT="P2"

######################
ELEMENTNAME="P1"; 
if [ "$ELEMENT" == "P2" ]; then ELEMENTNAME=""; fi
CONFIG_NAMES="$( cd ./config; echo ${SIM_PREFIX}* | grep -Po "${SIM_PREFIX}[^_]*" )"
######################
for CONFIG_NAME in $CONFIG_NAMES; do

    MESH_NAME="${CONFIG_NAME}"
    
    SIM_NAME="${CONFIG_NAME}${ELEMENTNAME}"

    # FÜR NUR EINEN MESH BENUTZE FLAG -i"0" -s; ersteres gibt Index vor und zweiteres sagt, nur eine Iteration
    # UND FÜR SIM EBEFALLS -i"0"

    #  --- MESH ---    
    ./config.sh -k "MESH" -n "1" -S "$MESH_NAME" -M "$MESH_NAME" -F "$CONFIG_NAME" -o "outputMesh" 
    
    sbatch -W -N1 -t20 ./slurmJobSim.sh -t 40 -j "" -n "1" -m "4000" -b "0" -p "buildMesh" -S "outputMesh/$MESH_NAME"

    # --- SIM ---

    #
    ./config.sh -k "SIM" -n "1" -S "$SIM_NAME" -M "$MESH_NAME" -F "$CONFIG_NAME"
    # for GRID 
    sbatch -W -N1 -t60 ./slurmJobSim.sh -t 80 -n "32" -m "2750" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 0
    # for RND2CC2048 sbatch -N12 -t160 ./slurmJobSim.sh -t 40 -n "320" -m"3250" -S "output/$SIM_NAME" -p "simulationP1BEMEff2" -b 0

    #for i in $( seq 14 17 ); do
    #sbatch -N12 -t180 ./slurmJobSim.sh -t 40 -n "320" -m"3250" -S "output/$SIM_NAME" -p "simulationP1BEMEff2" -b $i
    #done
    
    
    
    #./slurmJobSim.sh -t 40 -n "1" -S "output/TESTSH" -p "simulationP1BEMEff" -b 1

    #for idx in $( seq 0 0 ); do
    #    sbatch -N28 -t300 ./slurmJobSimSkipInd.sh -b"${idx}" -k -c"8" -n"768" -m"3200" -p"P1BEMEff" -S"$SIM_NAME" -M"$MESH_NAME" -F"$CONFIG_NAME"
    #done
    #./slurmJobSimSkip.sh -k -c"1" -n"8" -m"2700" -p"P1BEMEff" -S"$SIM_NAME" -M"$MESH_NAME" -F"$CONFIG_NAME"
done

#squeue -uaarifi --format="%o, %D, %t, %A" | grep -P "RNDC12048"  | grep -Po "\d*$" | xargs -i scancel {}
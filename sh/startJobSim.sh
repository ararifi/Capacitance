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

export WITH_SIM=true;
export WITH_MESH=true;
export ELEMENT="P2";
export NAME;


while getopts 'smp:n:' opt
do 
    case $opt in
        s) WITH_SIM=false;; 
        m) WITH_MESH=false;;
        p) ELEMENT="$OPTARG";; #P1, P2, P2Plt
        n) NAME="$OPTARG";;
    esac
done

# function that exit script if file is not in configDir
if [ ! -f "$configDir/${NAME}_"*".edp" ]; then
    echo "File $NAME does not exist in $configDir"
    exit 1
fi


#------------------------------------------------------------
# SLURM EXECUTION
#------------------------------------------------------------

#1, CHUNKS=18 SIM_PREFIX="RND2CC2048"

SIM_PREFIX="$NAME"

######################
ELEMENTNAME="$ELEMENT"; 
if [ "$ELEMENT" == "P2" ]; then ELEMENTNAME=""; fi
CONFIG_NAMES="$NAME"
#"$( cd ./config; echo ${SIM_PREFIX}* | grep -Po "${SIM_PREFIX}[^_]*" )"
######################
for CONFIG_NAME in $CONFIG_NAMES; do

    MESH_NAME="${CONFIG_NAME}"
    
    SIM_NAME="${CONFIG_NAME}${ELEMENTNAME}"

    # FÜR NUR EINEN MESH BENUTZE FLAG -i"0" -s; ersteres gibt Index vor und zweiteres sagt, nur eine Iteration
    # UND FÜR SIM EBEFALLS -i"0"

    if $WITH_MESH; then

        NUM_CHUNKS_MESH=2;

        #  --- MESH ---    
        ./config.sh -k "MESH" -n "$NUM_CHUNKS_MESH" -S "$MESH_NAME" -M "$MESH_NAME" -F "$CONFIG_NAME" -o "outputMesh" #-i"4" -j"4" -s
        ToDo="$( cat "outputMesh/${MESH_NAME}/${MESH_NAME}_indJobToDo.log" | sed 's/ /,/g' )"
        sbatch --array="0-$(( $NUM_CHUNKS_MESH - 1 ))" -N1 -t40 ./slurmJobSim.sh -t 40 -j "" -n "32" -m "2700" -b "-1" -p "buildMesh" -S "outputMesh/$MESH_NAME"

        #./slurmJobSim.sh -t 40 -j "1" -n "1" -m "10800" -b "0" -p "buildMesh" -S "outputMesh/$MESH_NAME"
        #for idx in $( seq 0 23 ); do
            #sbatch -W -N2 -t30 ./slurmJobSim.sh -t 40 -j "" -n "1" -m "5400" -b "$idx" -p "buildMesh" -S "outputMesh/$MESH_NAME"
        #done

    fi

    # --- SIM ---

    # BROADWELL 20 (2) mit 57000M
    # SKYLAKE 32 (2) mit 88500M


    if $WITH_SIM; then

        NUM_CHUNKS=2;            

        # BEIM REFRESHING OF CONFIG AUFPASSEN, DA SICH DANN 
        # DIE SIMULATION ÜPERLAPPEN KÖNNEN; DA JobToDOList aktualisiert obwohl vlt. ein anderer Job diesen am bearbeiten ist!!!
        ./config.sh -k "SIM" -n "$NUM_CHUNKS" -S "$SIM_NAME" -M "$MESH_NAME" -F "$CONFIG_NAME" #-i5 -j5 -s

        # ./config.sh -k "SIM" -n "$1" -S "$SIM_NAME" -M "$SIM_NAME" -F "$SIM_NAME"
        ToDo="$( cat "output/${SIM_NAME}/${SIM_NAME}_indJobToDo.log" | sed 's/ /,/g' )"
        #sbatch --array="0-3" -N1 -t60 ./slurmJobSim.sh -t 60 -n "32" -m "2700" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b -1
        #for RND #

        # PASS AUF BY array
        # FALLS JEDES ELEMENT EINEN EIGENEN JOB BEKOMMEN SOLL, DANN --array="$ToDo" ( BEACHTET DAS MANCHE MESHES NICHT EXISTIEREN )
        # FALLS CHUNKWEISE, DANN --array="0-$(( $NUM_CHUNKS - 1 ))"

        sbatch --array="0-$(( $NUM_CHUNKS - 1 ))" -N2 -t60 ./slurmJobSim.sh -t 180 -n "32" -m "2700" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 
        #sbatch --array="$ToDo" -N4 -t60 ./slurmJobSim.sh -t 80 -n "64" -m "5400" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b -1
        #for chunk in $( seq 0 $(( NUM_CHUNKS - 1 )) ); do
        #    sbatch -N1 -t80 ./slurmJobSim.sh -t 80 -n "64" -m "5400" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b $chunk
        #done
#

        #sbatch --array="1" -N4 -t40 ./slurmJobSim.sh -t 80 -n "64" -m "5400" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b -1
        #sbatch --array="1" -N1 -t40 ./slurmJobSim.sh -t 80 -n "32" -m "2700" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b -1
        #for idx in $( seq 0 47 ); do
        ##for idx in $( seq 2 2 ); do
        #    sbatch -N9 -t90 ./slurmJobSim.sh -t 180 -n "96" -m "8250" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b $idx
        #done
#
        # for GRID 
        #sbatch -N12 -t60 ./slurmJobSim.sh -t 180 -n "96" -m "11000" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 0

        #sbatch -N12 -t90 ./slurmJobSim.sh -t 180 -n "96" -m "11000" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 1

        #sbatch -N12 -t60 ./slurmJobSim.sh -t 180 -n "96" -m "11000" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 2

        #sbatch -N12 -t60 ./slurmJobSim.sh -t 180 -n "96" -m "11000" -S "output/$SIM_NAME" -p "simulation${ELEMENT}EffVol" -b 3

    fi
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
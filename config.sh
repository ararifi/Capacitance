# FIX PATH AND CREATE ALIAS FOR FREEFEM++
#------------------------------------------------------------

#SCRIPTPATH="/home/aarifi/Projects/Capacitance"
#export SCRIPTPATH

# --- !!! ---
#cd $SCRIPTPATH
# --- !!! ---

if ! command -v FreeFem++ &> /dev/null; then
    source alias.sh
fi

#------------------------------------------------------------
# DEFAULT
#------------------------------------------------------------

dirRoot="data"
dirOutput="$dirRoot/output"
dirMesh="$dirRoot/mesh"
dirConfig="$dirRoot/config"
dirSlurm="$dirRoot/slurm"
dirSlurmMesh="$dirRoot/slurmMesh"

dirBase="base"
dirIco="pkgMesh/meshSicosphere/meshS/"
export FF_INCLUDEPATH="$dirBase"
export FF_LOADPATH="$dirBase"

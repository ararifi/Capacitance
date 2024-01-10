# FIX PATH AND CREATE ALIAS FOR FREEFEM++
#------------------------------------------------------------

SCRIPTPATH="/home/aarifi/Projects/Capacitance"
export SCRIPTPATH

# --- !!! ---
cd $SCRIPTPATH
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

dirBase="/home/aarifi/Projects/Capacitance/base"
dirIco="/home/aarifi/Projects/Capacitance/pkgMesh/meshSicosphere/meshS/"
export FF_INCLUDEPATH="$dirBase"
export FF_LOADPATH="$dirBase"

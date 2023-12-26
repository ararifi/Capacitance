#!/bin/bash

# ----------------------------------------------------
# SET PATH AND DIRS
# ----------------------------------------------------

# script path
echo $SCRIPTPATH
[ ! -v $SCRIPTPATH ] && cd $SCRIPTPATH || ( echo "PARENT SCRIPTPATH NOT DEFINED"; exit )

outputFileDir=$1

# ----------------------------------------------------
# CREATE bmacro.idp
# ----------------------------------------------------

idp=${outputFileDir}/bMacro.idp; :> $idp

argLimit=512; 

# deltaUZero

numEpoch=$(( (maxMeteor + 6 + argLimit - 1) / argLimit  ))
for epoch in $( seq 1 $numEpoch ); do
    str="macro deltaUZero$epoch(u)"

    left=$(( 1 + (epoch-1)*argLimit ))
    right=$(( 1 + epoch*argLimit ))
    if [ $right -gt $(( maxMeteor + 6 )) ]; then
        right=$(( maxMeteor + 6 ))
    fi
    strNum="$( seq -s , $left $right )"
    str="${str}on($strNum, u=0)//"
    echo $str >> $idp
done

str="macro deltaUZero(u)"
for epoch in $( seq 1 $numEpoch ); do 
    str+="deltaUZero$epoch(u)+"
done
str="${str%+}//"; echo $str >> $idp

# deltaUOneMeteor

numEpoch=$(( (maxMeteor + argLimit - 1) / argLimit  ))
for epoch in $( seq 1 $numEpoch ); do
    str="macro deltaUOneMeteor$epoch(u)"

    left=$(( 7 + (epoch-1)*argLimit ))
    right=$(( 7 + epoch*argLimit ))
    if [ $right -gt $(( maxMeteor + 6 )) ]; then
        right=$(( maxMeteor + 6 ))
    fi
    strNum="$( seq -s , $left $right )"
    str="${str}on($strNum, u=1)//"
    echo $str >> $idp
done
str="macro deltaUOneMeteor(u)"
for epoch in $( seq 1 $numEpoch ); do 
    str+="deltaUOneMeteor$epoch(u)+"
done
str="${str%+}//"; echo $str >> $idp

# deltaUZeroMeteor

numEpoch=$(( (maxMeteor + argLimit - 1) / argLimit  ))
for epoch in $( seq 1 $numEpoch ); do
    str="macro deltaUZeroMeteor$epoch(u)"

    left=$(( 7 + (epoch-1)*argLimit ))
    right=$(( 7 + epoch*argLimit ))
    if [ $right -gt $(( maxMeteor + 6 )) ]; then
        right=$(( maxMeteor + 6 ))
    fi
    strNum="$( seq -s , $left $right )"
    str="${str}on($strNum, u=0)//"
    echo $str >> $idp
done
str="macro deltaUZeroMeteor(u)"
for epoch in $( seq 1 $numEpoch ); do 
    str+="deltaUZeroMeteor$epoch(u)+"
done
str="${str%+}//"; echo $str >> $idp


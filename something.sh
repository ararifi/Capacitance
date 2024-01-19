#!/bin/bash

for ((i=1;i<=1;i++)); do
    name="convergenceArrayNear$i"
    echo $name
    #./runMeshEnsemble.sh -m "$name" -c "$name" -M "2700"
    ./runEnsemble.sh -s "${name}Periodic" -m "$name" -c "$name" -M "2700" -N "8"
done
#!/bin/bash

name="$1"

export IS_CLUSTER="true"

"./runMesh.sh -m "$name" -c "$name" -p "$name" -M"2700" -i {}"

"./run.sh -s "$name" -m "$name" -c "$name" -N"32" -M"2700" -i {}"

parallel "$cmd" ::: "$( seq 6 6 )"  

for dim in $( seq 3 2 5 ); do 
    name=cubic_$dim
    sbatch --array=1-4 -N1 -t60 ./run.sh -s "$name" -m "$name" -c "$name" -N"32" -M"2700"
done 
for dim in $( seq 7 2 9 ); do 
    name=cubic_$dim
    sbatch --array=1-4 -N4 -t60 ./run.sh -s "$name" -m "$name" -c "$name" -N"128" -M"2700"
done  
# sbatch -N1 -t30 parallel ./runMesh.sh -m "$name" -c "$name" -p "$name" -M"2700" -i {} ::: "$( seq 1 4 )"

for dim in $( seq 11 11 ); do 
    name=cubic_$dim
    sbatch -N1 -t30 ./smallScript.sh "$name"
done  
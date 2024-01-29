#!/bin/bash

name="$1"

export IS_CLUSTER="true"

"./runMesh.sh -m "$name" -c "$name" -p "$name" -M"2700" -i {}"

"./run.sh -s "$name" -m "$name" -c "$name" -N"32" -M"2700" -i {}"

parallel "$cmd" ::: "$( seq 6 12 )"  
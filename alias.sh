#!/bin/bash

shopt -s expand_aliases

# Define aliases
#alias FreeFem++="apptainer run /home/aarifi/Projects/FreeFem_Sandbox FreeFem++"
#alias FreeFem++-mpi="apptainer run /home/aarifi/Projects/FreeFem_Sandbox FreeFem++-mpi"
#alias ff-mpirun="apptainer run /home/aarifi/Projects/FreeFem_Sandbox ff-mpirun"
#alias mpirun="apptainer run /home/aarifi/Projects/FreeFem_Sandbox /usr/freefem/ff-petsc/r/bin/mpirun"  
alias ff-shell="apptainer shell /home/aarifi/Projects/FreeFem_Sandbox"
alias ls="ls --color=auto"
alias rm='rm -i'

# alias mogon /lustre/project/m2_jgu-binaryhpc/aarifi/Capacitance

mogon_setup="--no-home --bind /lustre/project/m2_jgu-binaryhpc/aarifi/Capacitance:/home/aarifi/Projects/Capacitance --pwd /home/aarifi/Projects/Capacitance ${HOME}/cnts/ff"

alias FreeFem++="apptainer run $mogon_setup FreeFem++"

alias FreeFem++-mpi="apptainer run $mogon_setup FreeFem++-mpi"

alias mpirun="apptainer run $mogon_setup /usr/freefem/ff-petsc/r/bin/mpirun"

alias FreeFem++-mpi-shell="apptainer shell $mogon_setup ${HOME}/cnts/ff"
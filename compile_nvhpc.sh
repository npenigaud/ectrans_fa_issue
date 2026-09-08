#!/bin/bash

export FC=nvfortran
export FCC="-acc=gpu -Minfo=accel,all,intensity,ccff -gpu=lineinfo -O3 -fopenmp -gpu=deepcopy"
#export FCC="-O3"


module load nvidia/24.5
$FC $FCC -o main.x main.F90



#!/bin/bash

#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 6Gb     # Memory in GB
#SBATCH -J FASTQC
#SBATCH -o /users/genomics/marta/logs/FASTQC.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/FASTQC.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

file=$1
CLUSTERDIR=$2
OUTDIR=$3

module load FastQC/0.11.5-Java-1.7.0_80

fastqc -t $SLURM_CPUS_PER_TASK -I -O $CLUSTERDIR $file

name=${file##*/}
name=${name%%_*}

scp -rp $CLUSTERDIR/$name* marta@hydra:$OUTDIR
rm -r $CLUSTERDIR/$name*

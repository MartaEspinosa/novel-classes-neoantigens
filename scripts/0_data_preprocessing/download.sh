#!/bin/bash

#SBATCH -p long,bigmem            # Partition to submit to
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu 14Gb           # Memory in GB
#SBATCH -J dwnl           # job name
#SBATCH -o /users/genomics/marta/logs/dwnl.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/dwnl.%j.err    # File to which standard err will be written

CLUSTERDIR=$1
line=$2
INDIR=$3

module load SRA-Toolkit/2.9.2

fastq-dump --split-files -I -O $CLUSTERDIR $line
gzip ${CLUSTERDIR}/${line}*

scp -rp ${CLUSTERDIR}/${line}*gz marta@hydra:$INDIR
rm -r ${CLUSTERDIR}/${line}*gz


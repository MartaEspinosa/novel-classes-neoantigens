#!/bin/bash

#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 8Gb     # Memory in GB
#SBATCH -J FASTQC
#SBATCH -o /users/genomics/marta/logs/FASTQC.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/FASTQC.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#1_ ARGV[1] = GEO code
PROJECT=$1

#2_ ARGV[2] = Cluster path
CLUSTERDIR=$2/${PROJECT}/03_fastqc
mkdir $CLUSTERDIR

#3_ ARGV[3] = Path to fastq files
FASTQDIR=$3

#4_ ARGV[4] = Path to store the output (locally)
OUTDIR=$4/analysis/03_fastqc

for file in ${FASTQDIR}/*_1*.gz; do 
    sbatch fastqc.sh $file $CLUSTERDIR $OUTDIR
done 

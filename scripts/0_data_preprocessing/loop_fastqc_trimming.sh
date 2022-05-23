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
CLUSTERDIR=$2/${PROJECT}/04_cutadapt
mkdir $CLUSTERDIR
CLUSTERDIR=$CLUSTERDIR/fastqc
mkdir $CLUSTERDIR

#3_ ARGV[3] = Local path
DIR=$3/analysis/04_cutadapt
OUTDIR=$3/analysis/04_cutadapt/fastqc

for file in ${DIR}/*.gz; do 
    sbatch fastqc.sh $file $CLUSTERDIR $OUTDIR
done 

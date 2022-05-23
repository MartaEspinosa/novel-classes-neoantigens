#!/bin/bash

#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 5Gb     # Memory in GB
#SBATCH -J FastQScreen          # job name
#SBATCH -o /users/genomics/marta/logs/FastQScreen.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/FastQScreen.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#1_ ARGV[1] = GEO code
PROJECT=$1 #GSE193567

#2_ ARGV[2] = cluster path
CLUSTERDIR=$2/${PROJECT}/02_fastqscreen
mkdir $CLUSTERDIR

#3_ ARGV[3] = Path to fastq files
FASTQDIR=$3 #/projects_eg/datasets/GSE193567/fastq_files

#4_ ARGV[4] = Path to store the output (locally)
OUTDIR=$4/analysis/02_fastqscreen

for file in $FASTQDIR/*gz; do
    sbatch fastqscreen.sh $file $CLUSTERDIR $OUTDIR $5
    sleep 1
done

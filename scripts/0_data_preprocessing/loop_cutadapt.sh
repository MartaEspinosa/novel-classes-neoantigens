#!/bin/bash

#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 7Gb 
#SBATCH -J cutadapt_loop           # job name
#SBATCH -o /users/genomics/marta/logs/cutadapt_loop.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/cutadapt_loop.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#1_ ARGV[1] = GEO code
PROJECT=$1

#2_ ARGV[2] = Cluster path
CLUSTERDIR=$2/${PROJECT}/04_cutadapt
mkdir $CLUSTERDIR

#3_ ARGV[3] = Path to fastq files
FASTQDIR=$3

#4_ ARGV[4] = Path to store the output (locally)
OUTDIR=$4/analysis/04_cutadapt

for i in $(ls $FASTQDIR/*_1.fastq.gz | sed 's/_1.fastq.gz//'); do
    name=`basename $i`
    sbatch cutadapt.sh $name $PROJECT $CLUSTERDIR $FASTQDIR $OUTDIR $5
done

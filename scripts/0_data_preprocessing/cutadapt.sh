#!/bin/bash

#SBATCH --partition=normal,long
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 10Gb           # Memory in GB
#SBATCH -J cutadapt           # job name
#SBATCH -o /users/genomics/marta/logs/cutadapt.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/cutadapt.%j.err    # File to which standard err will be written

module load Python/3.5.2-foss-2016b

name=$1
PROJECT=$2
CLUSTERDIR=$3
FASTQDIR=$4
OUTDIR=$5

ext1=_1.fastq.gz
ext2=_2.fastq.gz

R1=_trimmed_1.fastq.gz
R2=_trimmed_2.fastq.gz


cutadapt -j $SLURM_CPUS_PER_TASK -O 5 -q 30 -m 26 -b file:$6/adapters.fa -o ${CLUSTERDIR}/$name$R1 -p ${CLUSTERDIR}/$name$R2 ${FASTQDIR}/$name$ext1 ${FASTQDIR}/$name$ext2 > ${CLUSTERDIR}/${name}_cutadapt.log 

scp -rp ${CLUSTERDIR}/$name$R1 marta@hydra:$OUTDIR
rm -r ${CLUSTERDIR}/$name$R1


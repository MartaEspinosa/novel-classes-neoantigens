#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 5Gb     # Memory in GB
#SBATCH -J FastQScreen           # job name
#SBATCH -o /users/genomics/marta/logs/FastQScreen.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/FastQScreen.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#-------------------------------

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load fastq_screen/0.14.0
module load Bowtie2/2.3.5.1             # Required for Fastqscreen


FASTQ=$1
CLUSTERDIR=$2
OUTDIR=$3
config=$4/Index_Genomes_Bowtie2/fastq_screen.conf
#-------------------------------


fastq_screen --threads $SLURM_CPUS_PER_TASK --conf $config --outdir $CLUSTERDIR $FASTQ

name=${FASTQ##*/}
name=${name%%_*}

scp -rp $CLUSTERDIR/$name* marta@hydra:$OUTDIR
rm -r $CLUSTERDIR/$name*

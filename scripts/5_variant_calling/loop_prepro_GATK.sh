#!/bin/bash

#SBATCH -p short,lowmem	             # Partition to submit to (12h)
#SBATCH --cpus-per-task=1            # Number of cores (chosen from scale test)
#SBATCH --mem-per-cpu 20Gb           # Memory in MB
#SBATCH -J loop_preprocess           	# job name
#SBATCH -o /users/genomics/marta/logs/loop_preprocess.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/loop_preprocess.%j.err    # File to which standard err will be written

PROJECT=$1
DIR=$2
FASTQDIR=$3
CLUSTERDIR=$4/${PROJECT}/13_VariantCalling
mkdir $CLUSTERDIR

patients_pairs=$5
GENOMEDIR=$6

while IFS=, read patient normal tumor; do
    echo ${patient}
    INFILE=$DIR/analysis/05_STAR/uniquely_mapped_2pass_BAM_files
    sbatch preprocess_GATK4.sh $INFILE $normal $CLUSTERDIR $FASTQDIR $DIR/analysis/13_VariantCalling $GENOMEDIR
    sbatch preprocess_GATK4.sh $INFILE $tumor $CLUSTERDIR $FASTQDIR $DIR/analysis/13_VariantCalling $GENOMEDIR

    sleep 1
done < $patients_pairs



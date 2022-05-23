#!/bin/bash

#SBATCH -p short,lowmem	             # Partition to submit to (12h)
#SBATCH --cpus-per-task=1            # Number of cores (chosen from scale test)
#SBATCH --mem-per-cpu 20Gb           # Memory in MB
#SBATCH -J loop_variantcalling           	# job name
#SBATCH -o /users/genomics/marta/logs/loop_variantcalling.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/loop_variantcalling.%j.err    # File to which standard err will be written

PROJECT=$1
DIR=$2
CLUSTERDIR=$3/${PROJECT}/13_VariantCalling

patients_pairs=$DIR/results/patients.csv
GENOMEDIR=$4

while IFS=, read patient normal tumor; do
    echo ${patient}
    INFILE=$DIR/analysis/13_VariantCalling
    sbatch variantcalling.sh $INFILE $normal $tumor $patient $CLUSTERDIR $DIR $GENOMEDIR

    sleep 1
done < $patients_pairs



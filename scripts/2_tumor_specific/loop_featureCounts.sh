#!/bin/bash

#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 20Gb           # Memory in MB
#SBATCH -J featCounts           # job name
#SBATCH -o /users/genomics/marta/logs/featCounts.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/featCounts.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

## BUILD VARS AND CREATE FOLDERS
PROJECT=$1
CLUSTERDIR=$2/${PROJECT}/07_quantification
mkdir $CLUSTERDIR

DIR=$3
patients_summary=$4

while IFS=, read patient normal tumor; do
    echo -e  "${patient}\t${normal}\t${tumor}"
# feature counts is done by patient. Paired normal and tumor samples are quantified considering the tumor transcriptome
    sbatch featureCounts.sh $patient $normal $tumor $CLUSTERDIR/${patient} $DIR

    sleep 1
done < $patients_summary

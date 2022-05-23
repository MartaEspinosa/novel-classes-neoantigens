#!/bin/bash

#SBATCH -p lowmem            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 15Gb           # Memory in MB
#SBATCH -J STAR           # job name
#SBATCH -o /users/genomics/marta/logs/STAR.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/STAR.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

## BUILD VARS AND CREATE FOLDERS
PROJECT=$1
CLUSTERDIR=$2/${PROJECT}/uniquely_mapped_2pass_BAM_files
mkdir $CLUSTERDIR

DIR=$3
patients_pairs=${DIR}/results/patients.csv

GENOMEDIR=$4

while IFS=, read patient normal tumor; do
    echo -e  "${patient}\t${normal}\t${tumor}"
    sbatch STAR.sh $patient $normal $CLUSTERDIR $DIR $GENOMEDIR
    sbatch STAR.sh $patient $tumor $CLUSTERDIR $DIR $GENOMEDIR

    sleep 1
done < $patients_pairs


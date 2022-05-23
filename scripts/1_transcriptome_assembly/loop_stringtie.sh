
#!/bin/bash

#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 8Gb           # Memory in MB
#SBATCH -J STRINGTIE           # job name
#SBATCH -o /users/genomics/marta/logs/STRINGTIE.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/STRINGTIE.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

## INPUT
PROJECT=$1

## BUILD VARS AND CREATE FOLDERS
CLUSTERDIR=$2/${PROJECT}/06_stringtie
mkdir $CLUSTERDIR

DIR=$3
BAMDIR=$DIR/analysis/05_STAR/uniquely_mapped_2pass_BAM_files

GENOMEDIR=$4


for file in ${BAMDIR}/*Aligned.sortedByCoord.out.bam; do
    	sbatch stringtie.sh $file $CLUSTERDIR $GENOMEDIR $DIR
done

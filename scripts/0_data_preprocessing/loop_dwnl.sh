#!/bin/bash

#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 8Gb           # Memory in GB
#SBATCH -J dwnl           # job name
#SBATCH -o /users/genomics/marta/logs/dwnl.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/dwnl.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#1_ ARGV[1] = Path where SRR_Acc_List.txt is stored
INDIR=$1 #/projects_eg/datasets/GSE193567

#2_ ARGV[2] = GEO code
PROJECT=$2 #GSE193567

#3_ ARGV[3] = cluster path
CLUSTERDIR=$3/${PROJECT}
mkdir $CLUSTERDIR

CLUSTERDIR=${CLUSTERDIR}/fastq_files
mkdir $CLUSTERDIR

#2_ download each sample
while IFS="\n" read line; # one accession id per line
do
sbatch download.sh $CLUSTERDIR $line $INDIR
done < ${INDIR}/SRR_Acc_List.txt

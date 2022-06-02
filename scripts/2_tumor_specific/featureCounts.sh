#!/bin/bash

#SBATCH -p bigmem,long,normal            # Partition to submit to
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu 9Gb           # Memory in MB
#SBATCH -J featCounts           # job name
#SBATCH -o /users/genomics/marta/logs/featCounts.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/featCounts.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

patient=$1
normal=$2
tumor=$3
CLUSTERDIR=$4
mkdir $CLUSTERDIR
DIR=$5

module load subread/2.0.3

BAM=$DIR/analysis/05_STAR/uniquely_mapped_2pass_BAM_files
# only the tumor transcriptome is used, since we are only interested in things present in the tumor
GTF=$DIR/analysis/06_stringtie/stringtie_reference_annotations/${tumor}_reference_annotation_sorted.gtf
COUNTS=${CLUSTERDIR}/${patient}_featureCounts.txt

# countReadPairs may need to be removed in case of single-end reads
# only tumor transcriptome but both normal and tumor bam files are required
featureCounts -p --countReadPairs -a $GTF -o $COUNTS ${BAM}/${normal}Aligned.sortedByCoord.out.bam ${BAM}/${tumor}Aligned.sortedByCoord.out.bam

scp -rp $COUNTS marta@hydra:$DIR/analysis/07_quantification
rm -r $COUNTS


#!/bin/bash

#SBATCH -p bigmem,long            # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 12Gb           # Memory in MB
#SBATCH -J STAR           # job name
#SBATCH -o /users/genomics/marta/logs/STAR.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/STAR.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

module load STAR/2.7.1a-foss-2016b

ANNOTGENE=$5/Annot_files_GTF
GNMIDX=$5/Index_Genomes_STAR/Idx_Gencode_v38_hg38_readlength45

## INPUT
PATIENT=$1
SAMPLE=$2
CLUSTERDIR=$3
DIR=$4

FASTQDIR=$DIR/analysis/04_cutadapt


R1=_trimmed_1.fastq.gz
R2=_trimmed_2.fastq.gz #this should be commented if the dataset is single-end

######################################################################################################
#####################################ALIGNMENT########################################################

#gzip fastq files are considered in the code, as well as paired-end reads samples.
#two pass mode is activated
#output with uniquely mapped reads ONLY
STAR --runThreadN $SLURM_CPUS_PER_TASK\
 --genomeDir $GNMIDX --readFilesCommand zcat --readFilesIn ${FASTQDIR}/$SAMPLE$R1 ${FASTQDIR}/$SAMPLE$R2 --outFileNamePrefix\
 ${CLUSTERDIR}/$SAMPLE --outSAMattributes All --outSAMtype BAM SortedByCoordinate --outSAMmapqUnique 60 --outFilterType BySJout\
 --outFilterMultimapNmax 1 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999\
 --outFilterMismatchNoverLmax 0.05 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000\
 --sjdbGTFfile $ANNOTGENE/gencode.v38.primary_assembly.annotation.gtf --twopassMode Basic
 
######################################################################################################
#########################################INDEX########################################################


module purge
module load SAMtools/1.8-foss-2016b


samtools index ${CLUSTERDIR}/${SAMPLE}Aligned.sortedByCoord.out.bam ${CLUSTERDIR}/${SAMPLE}Aligned.sortedByCoord.out.bai

scp -rp ${CLUSTERDIR}/${SAMPLE}* "$(whoami)"@"$(hostname -s)":$DIR/analysis/05_STAR/uniquely_mapped_2pass_BAM_files
rm -r ${CLUSTERDIR}/${SAMPLE}*


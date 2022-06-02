#!/bin/bash
#SBATCH -p normal,long         # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 15Gb	# Memory in MB
#SBATCH -J nfHLA           # job name
#SBATCH -o /users/genomics/marta/logs/nfHLA.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/nfHLA.%j.err    # File to which standard err will be written

module load Java
module load singularity/3.2.0-foss-2016b

PROJECT=$1
INDIR=$2
CLUSTERDIR=$3
patient=$4
normal=$5
tumor=$6
OUTDIR=$7

fileN=${INDIR}/${normal}_{1,2}.fastq.gz #we only use the normal sample to avoid possible mutations the the HLA alleles in the tumor samples

/genomics/users/marta/tools/nextflow run nf-core/hlatyping -profile singularity --seqtype rna --input $fileN --outdir $CLUSTERDIR/$patient --enumerations 3

scp -rp ${CLUSTERDIR}/${patient}* marta@hydra:$OUTDIR/analysis/10_HLAtyping
rm -r ${CLUSTERDIR}/${patient}*

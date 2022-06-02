#!/bin/bash

#SBATCH -p short,normal,long             # Partition to submit to (12h)
#SBATCH --cpus-per-task=1            # Number of cores (chosen from scale test)
#SBATCH --mem-per-cpu 91Gb           # Memory in MB
#SBATCH -J preprocess           	# job name
#SBATCH -o /users/genomics/marta/logs/preprocess.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/preprocess.%j.err    # File to which standard err will be written


module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load SAMtools/1.9-foss-2016b
module load picard/2.18.12-Java-1.8.0_92
module load GATK/4.2.0.0

# grab filename base and create output directory
INFILE=$1
SAMPLE=$2
CLUSTERDIR=$3
FASTQ=$4
DIR=$5
REF=$6/GRCh38/GRCh38.primary_assembly.genome.fa
REFfile=${REF##*/}
version=${REFfile%%.*}

INDELS=$6/GATK_bundle/Mills_and_1000G_gold_standard.indels.only-chr1toY.hg38.vcf.gz
SNP1=$6/GATK_bundle/dbsnp_146.hg38.vcf.gz
SNP2=$6/GATK_bundle/1000G_phase1.snps.high_confidence.hg38.vcf

OUTDIR=$CLUSTERDIR/${SAMPLE}
mkdir $OUTDIR

# add readgoups, this part may have to be customized depending on fastq headers
#HD=$(zcat $FASTQ/${SAMPLE}_1.fastq.gz | head -1)
#IFS=: read instrument run flowcell lane title x y  <<< $HD
#PL=ILLUMINA
#SM=$SAMPLE
#LB=lib$SAMPLE
##PU = [FLOWCELL].[LANE].[SAMPLE BARCODE]
#PU=HWI-ST1431.$lane.$flowcell
#ID=HWI-ST1431

HD=$(zcat $FASTQ/${SAMPLE}_1.fastq.gz | head -1)
IFS=: read instrument run flowcell lane title x y  <<< $HD
PL=ILLUMINA
SM=$SAMPLE
LB=lib$SAMPLE
##PU = [FLOWCELL].[LANE].[SAMPLE BARCODE]
PU=HWI-ST1431.FLOWCELL
ID=HWI-ST1431

gatk AddOrReplaceReadGroups \
    --INPUT $INFILE/${SAMPLE}Aligned.sortedByCoord.out.bam \
    --OUTPUT $OUTDIR/${SAMPLE}.rg.bam \
    --RGID $ID \
    --RGLB $LB \
    --RGPL $PL \
    --RGPU $PU \
    --RGSM $SM 

samtools index $OUTDIR/${SAMPLE}.rg.bam

#mark duplicates
gatk MarkDuplicates \
    --INPUT $OUTDIR/$SAMPLE.rg.bam \
    --OUTPUT $OUTDIR/$SAMPLE.rg.md.bam \
    --METRICS_FILE $OUTDIR/${SAMPLE}_marked_dup_metrics.txt
    
samtools flagstat $OUTDIR/$SAMPLE.rg.md.bam > $OUTDIR/$SAMPLE.rg.md.stats
samtools index $OUTDIR/$SAMPLE.rg.md.bam

#BaseRecalibration
gatk BaseRecalibrator \
    -I $OUTDIR/$SAMPLE.rg.md.bam \
    -R $REF \
    --known-sites $INDELS \
    --known-sites $SNP1 \
    --known-sites $SNP2 \
    --disable-read-filter MappingQualityAvailableReadFilter \
    -O $OUTDIR/$SAMPLE.recal.table


gatk ApplyBQSR \
    -R $REF \
    -I $OUTDIR/$SAMPLE.rg.md.bam \
    --bqsr-recal-file $OUTDIR/$SAMPLE.recal.table \
    -O $OUTDIR/$SAMPLE.recal.bam
    
scp -rp $OUTDIR marta@hydra:$DIR
rm -r $OUTDIR

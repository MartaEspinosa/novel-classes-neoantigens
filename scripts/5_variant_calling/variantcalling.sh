#!/bin/bash
#SBATCH -p short,normal,long           	  # Partition to submit to (12h)
#SBATCH --cpus-per-task=1         # Number of cores (chosen from scale test)
#SBATCH --mem-per-cpu 29Gb        # Memory in MB
#SBATCH -J variantcalling           	  # job name
#SBATCH -o /users/genomics/marta/logs/variantcalling.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/variantcalling.%j.err    # File to which standard err will be written


module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load GATK/4.2.0.0
module load Java/1.8.0_92

# grab filename base and create output directory
REF=$7/GRCh38/GRCh38.primary_assembly.genome.fa
gnomAD=$7/GATK_bundle/af-only-gnomad.hg38.vcf.gz
gnomAD_biallelic=$7/GATK_bundle/small_exac_common_3.hg38.vcf.gz
INTERVALS=$7/GATK_bundle/SureSelect.Human.AllExon.V5.50Mb_hs_hg38.interval_list

SM=$(echo $1 | cut -d"_" -f2)
SM=${SM//UDI/UDI-idt-UMI} ## -tumor name has to be the same as SM in read group
INFILE=$1
NORMAL=$2 #$1
TUMOR=$3 #$2
PATIENT=$4 #$3
DIR=$6
OUTDIR=$5/${PATIENT}
mkdir $OUTDIR


# We need to create this file
touch ${OUTDIR}/${PATIENT}_f1r2.tar.gz

#tumor with matched normal mode
gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m Mutect2 \
	-R $REF \
	-I $INFILE/${TUMOR}_indels/${TUMOR}.recal.bam \
	-I $INFILE/${NORMAL}_indels/${NORMAL}.recal.bam \
	--normal-sample $NORMAL \
	-L $INTERVALS \
	--germline-resource $gnomAD \
	--af-of-alleles-not-in-resource 0.0000025 \
	--bam-output ${OUTDIR}/${PATIENT}.bam \
	--f1r2-tar-gz ${OUTDIR}/${PATIENT}_f1r2.tar.gz \
	-O ${OUTDIR}/${PATIENT}.vcf.gz

gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m LearnReadOrientationModel \
            -I ${OUTDIR}/${PATIENT}_f1r2.tar.gz \
            -O ${OUTDIR}/${PATIENT}_artifact-priors.tar.gz

#Estimate Cross-sample contamination
#Summarize read support for a set number of known variant sites.
#Seaparately for NORMAL and TUMOR sample
gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m GetPileupSummaries \
        -I $INFILE/${TUMOR}_indels/${TUMOR}.recal.bam \
        -V $gnomAD_biallelic \
        -L $INTERVALS \
        -O ${OUTDIR}/${TUMOR}_getpileupsummaries.table

gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m GetPileupSummaries \
        -I $INFILE/${NORMAL}_indels/${NORMAL}.recal.bam \
        -V $gnomAD_biallelic \
        -L $INTERVALS \
        -O ${OUTDIR}/${NORMAL}_getpileupsummaries.table

#Takes the summary table from GetPileupSummaries and gives the fraction contamination. This estimation does not calculate TiN contamination. Rationale: If the homozygous alternate site has a rare allele, we are more likely to observe the presence of REF or other more common alleles if there is cross-sample contamination. This allows us to measure contamination more accurately.   
gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m CalculateContamination \
    -I ${OUTDIR}/${TUMOR}_getpileupsummaries.table \
    -matched ${OUTDIR}/${NORMAL}_getpileupsummaries.table \
    -O ${OUTDIR}/${PATIENT}_calculatecontamination.table 
    
#Filter confident somatic calls. This step applies 14 filters, including contamination. It applies a filter for removing duplicates
# -ob-priors:  # For FFPE orientation bias artifacts
gatk --java-options -Xmx${SLURM_MEM_PER_CPU}m FilterMutectCalls \
	-R $REF \
	-V ${OUTDIR}/${PATIENT}.vcf.gz \
	-ob-priors ${OUTDIR}/${PATIENT}_artifact-priors.tar.gz \
	--contamination-table ${OUTDIR}/${PATIENT}_calculatecontamination.table  \
	--filtering-stats ${OUTDIR}/${PATIENT}_filtering.stats \
	-O ${OUTDIR}/${PATIENT}_filtered.vcf.gz

scp -rp ${OUTDIR} "$(whoami)"@"$(hostname -s)":$DIR/analysis/13_VariantCalling


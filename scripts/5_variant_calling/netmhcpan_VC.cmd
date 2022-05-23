#!/bin/bash

#SBATCH -p lowmem,short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 15Gb     # Memory in MB
#SBATCH -J VCNetMHCpan          # job name
#SBATCH -o /users/genomics/marta/logs/VCNetMHCpan_%A_%a.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/VCNetMHCpan_%A_%a.err    # File to which standard err will be written

# Run NetMHCpan: 
PROJECT=$1
DIR=$2
patients_pairs=$DIR/results/patients.csv
OUTDIR=$3/${PROJECT}/11_PeptideBindingMHC
mkdir $OUTDIR
OUTDIR=$OUTDIR/variant_calling
mkdir $OUTDIR

# Declare a string array
declare -a array
declare -a patients_array

while IFS=, read patient normal tumor; do
    array=(${array[@]} $DIR/analysis/13_VariantCalling/peptide_prediction/${patient}/${patient}_filtered.PASS.DP.AD.missense_MTpeptide.fastq) # Add new element at the end of the array
    patients_array=(${patients_array[@]} $patient) # Add new element at the end of the array

done < $patients_pairs


i=$(($SLURM_ARRAY_TASK_ID -1))

INPUT=${array[i]}
patient=${patients_array[i]}
echo $patient

# Set path for software
module load netMHCpan/4.1

#=================#
# Run netMHCpan
#=================#

# Prepare variables
mkdir $OUTDIR/$patient

name=${INPUT##*/}
name=${name%%peptide*}
alleles_line="$( < $DIR/analysis/10_HLAtyping/${patient}_alleles_to_netMHCpan.csv)"


## RUN WITH Eluted ligand (default) + BA (bindinf affinities)
netMHCpan -a $alleles_line -f $INPUT -l 9 -BA -xls -xlsfile ${OUTDIR}/${patient}/${name}.netMHCpan.BA.xls >  ${OUTDIR}/${patient}/${name}.netMHCpan.BA.out


#======================#
# Create output xlsx   #
#======================#

# Load modules
#------------------
module load R/4.0.0

file=${OUTDIR}/${patient}/${name}*.netMHCpan.BA.xls

hla=$(head -1 $file | tr -s '\t' '\n' | sed -r '/^\s*$/d' | sort | uniq | wc -l)

Rscript $DIR/scripts/4_neoantigen_prediction/netmhcpan/parse_netmhcpan_EL_BA_out_MODIF_${hla}.R $file

pid=$!
wait $pid


scp -rp ${OUTDIR}/${patient} "$(whoami)"@"$(hostname -s)":$DIR/analysis/11_PeptideBindingMHC/variant_calling


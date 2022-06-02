#!/bin/bash

#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 30Gb     # Memory in MB
#SBATCH -J NetMHCpan_pc          # job name
#SBATCH -o /users/genomics/marta/logs/NetMHCpan_pc_%A_%a.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/NetMHCpan_pc_%A_%a.err    # File to which standard err will be written

PROJECT=$1
DIR=$2
CLUSTERDIR=$3/${PROJECT}/11_PeptideBindingMHC
mkdir $CLUSTERDIR
CLUSTERDIR=$CLUSTERDIR/canonical_CDS
mkdir $CLUSTERDIR

# Declare a string array
declare -a array
declare -a patients_array

while IFS=, read patient normal tumor; do
    array=(${array[@]} $DIR/analysis/08_tumor_specific/${patient}/${patient}_known_tumor_specific_genes_1FPKM_300kb_CDS_gene_PROTEIN.fa) # Add new element at the end of the array
    patients_array=(${patients_array[@]} $patient) # Add new element at the end of the array

done < $DIR/results/patients.csv

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
mkdir $CLUSTERDIR/$patient

name=${INPUT##*/}
name=${name%%.*}
alleles_line="$( < $DIR/analysis/10_HLAtyping/${patient}_alleles_to_netMHCpan.csv)"


## RUN WITH Eluted ligand (default) + BA (bindinf affinities)
netMHCpan -a $alleles_line -f $INPUT -l 9 -BA -xls -xlsfile ${CLUSTERDIR}/${patient}/${name}.netMHCpan.BA.xls >  ${CLUSTERDIR}/${patient}/${name}.netMHCpan.BA.out


#======================#
# Create output xlsx   #
#======================#

# Load modules
#------------------
module load R/4.0.0

file=${CLUSTERDIR}/${patient}/${name}*.netMHCpan.BA.xls

hla=$(head -1 $file | tr -s '\t' '\n' | sed -r '/^\s*$/d' | sort | uniq | wc -l)

Rscript $DIR/scripts/4_neoantigen_prediction/netmhcpan/parse_netmhcpan_EL_BA_out_MODIF_${hla}.R $file

pid=$!
wait $pid


scp -rp ${CLUSTERDIR}/${patient} marta@hydra:$DIR/analysis/11_PeptideBindingMHC/canonical_CDS


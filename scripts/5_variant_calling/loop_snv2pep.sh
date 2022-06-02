#!/bin/bash
#SBATCH -p short             # Partition to submit to (12h)
#SBATCH --cpus-per-task=1            # Number of cores (chosen from scale test)
#SBATCH --mem-per-cpu 58Gb           # Memory in MB
#SBATCH -J snv2pep           	# job name
#SBATCH -o /users/genomics/marta/logs/snv2pep.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/snv2pep.%j.err    # File to which standard err will be written

module load Python/3.6.2

PROJECT=$1
DIR=$2/analysis/13_VariantCalling
OUTDIR=$3/${PROJECT}/13_VariantCalling/peptide_prediction
#mkdir $OUTDIR


patients_pairs=$2/results/patients.csv
K=9 #peptide length

cat $patients_pairs | while IFS=, read patient normal tumor; do
    file=${DIR}/${patient}/${patient}_filtered.PASS.DP.AD.missense.vep
    python3 snv2pep_vepENSP.py -i ${file} -o ${OUTDIR} -k ${K}
done
echo "### FINISHED snv2pep.###"
echo "Output files in $OUTDIR"

scp -rp ${OUTDIR} marta@hydra:$DIR

#!/bin/bash
#SBATCH -p short         # Partition to submit to
#SBATCH --mem 10Gb
#SBATCH -J nfHLA           # job name
#SBATCH -o /users/genomics/marta/logs/nfHLA.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/nfHLA.%j.err    # File to which standard err will be written


PROJECT=$1
INDIR=$2
CLUSTERDIR=$3/${PROJECT}/10_HLAtyping
mkdir $CLUSTERDIR
OUTDIR=$4

while IFS=, read patient normal tumor; do
    echo ${patient}
    sbatch hlatyp.sh $PROJECT $INDIR $CLUSTERDIR $patient $normal $tumor $OUTDIR
    
    sleep 1
done < $5

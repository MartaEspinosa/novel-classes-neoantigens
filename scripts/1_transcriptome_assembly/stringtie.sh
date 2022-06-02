#!/bin/bash

#SBATCH -p bigmem,long,normal            # Partition to submit to
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 5Gb           # Memory in MB
#SBATCH -J STRINGTIE           # job name
#SBATCH -o /users/genomics/marta/logs/STRINGTIE.%j.out    # File to which standard out will be written
#SBATCH -e /users/genomics/marta/logs/STRINGTIE.%j.err    # File to which standard err will be written

####Change output and output error paths to redirect the log files generated 

#export PATH=/genomics/users/irubia/tools/stringtie2/:$PATH
module load stringtie/2.0

SAMPLE=$1
CLUSTERDIR=$2
ANNOTATION=$3/Annot_files_GTF/gencode.v38.primary_assembly.annotation.gtf
OUTDIR=$4

name=${SAMPLE%%Al*}
name=${name##*BAM_files/}

######################################################################################################
#####################################STRINGTIE########################################################

stringtie $SAMPLE -G $ANNOTATION -p $SLURM_CPUS_PER_TASK --conservative -o $CLUSTERDIR/${name}.gtf -C $CLUSTERDIR/${name}_cov.gtf

scp -rp $CLUSTERDIR/${name}* marta@hydra:$OUTDIR/analysis/06_stringtie
rm -r $CLUSTERDIR/${name}*


# novel-classes-neoantigens
Identification of novel classes of neoantigens in cancer, based on RNA-Seq data and datasets with normal/tumor paired data.

This approach uses RNA-Seq data to identify potential neoantigens coming from novel genes or non-coding genes with translatable open reading frames.
It goes from the raw fastq files to the generation of a list of peptides with binding affinity for the major histocompatibility complex.

Both Python3 and R languages are used, as well as bash.

### Requirements

`Requirements.txt` file contains all programas required to run the pipeline.

### Reference genome

GRCh38 human genome version is used and provided. Other version should work too, adding them in the genomes folder and modifying the corresponding paths.

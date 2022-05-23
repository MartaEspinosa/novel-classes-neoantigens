#!/usr/bin/env python
# coding: utf-8

# ## SNV to Peptide
# Programmer: Lilian Marie Boll (IMIM, Barcelona)
# Started 29th of October 2021
# Version 1.0
#
# Program to get k-mer Peptide Sequences from vcf files containing SNVs


# INPUT: takes v2_filtered.txt files generated after reannotating with
# run_vep.sh and filter_missense_AF.sh in /genomics/users/lilian/DATA/WES/02_Reannotate
# OUTPUT: fasta file for each patient containing a short part of the mutated transcripts around the mutation

#PIPELINE
# 1. takes the mutation saved in HGVSp
# 2. gets the transcript from ensembl
# (file provided in "/genomics/users/lilian/Data/WES/03_PeptidePredict/Homo_sapiens.GRCh37.75.pep.all.fa")
# 3. applies mutation to seq and saves to new column
# 4. cuts partition around the mutation to be given to NetMHC that will then cut the k-mer peptides

import os
import io
import re
import csv
import Bio
from Bio import SeqIO
import argparse
import pandas as pd
import numpy as np
import math
import requests, sys
from Bio.SeqUtils import seq1
from datetime import date

# __Input:__
# - vcf file (maf format), tab limited containing SNVs
# - p-length - peptide length (default= 8)
# Please edit ext in functin make_outdir() depending on file extension
# default .vep
#
# __Output:__
# - Fasta File of Peptide k-mer Seq
# ## MAIN
# 1. Process maf inputfile
#     pandas dataFrame
# 2. fetch ensembl seq to transcript
#     get_transSeq()
# 3. Add Mutation
#     apply_mut()
# 4. write Fasta
#     writefasta()
#
#  Get all tanscript IDs and Seqs from ensembl 75.75
#  from Homo_sapiens.GRCh37.75.pep.all_corrID.fa
#  Biopython offers the index() to handle big fasta files:
#  For larger files you should consider Bio.SeqIO.index(), which works a little differently. Although it
#  still returns a dictionary like object, this does not keep everything in memory. Instead, it just records where
#  each record is within the file – when you ask for a particular record, it then parses it on demand.


# ### Argument Parser to get input

parser =  argparse.ArgumentParser(description="Generating Peptide k-mer from SNVs")


parser.add_argument('-i', '--inputpath', dest='i',
                    type=str, required=True,
                    help='path to VCF File containing SNVs')
parser.add_argument('-k','--peptidelength', dest='k',
                    type=int, default=9,
                    help='Length of peptides that will be generated. Default=8')
parser.add_argument('-o', '--output', dest='o',
                    type=str,
                    help='path to folder where output files will be stored')
parser.add_argument('-d','--IDfile', dest='d',
                    type=str,
                    help='path to CSV File containing sampleID, patientID, CombID')
args = parser.parse_args()


def read_vcf(path):
    with open(path, 'r') as f:
        lines = [l for l in f if not l.startswith('##')]
        cols_list = ['#Uploaded_variation','Location','Amino_acids','Extra'] # import only needed columns
    return pd.read_csv(
        io.StringIO(''.join(lines)),
        usecols=cols_list,
        dtype={'#Uploaded_variation': str,'Location': str,'Amino_acids': str,'Extra': str},
        sep='\t').rename(columns={'#Uploaded_variation': 'ID'})


def get_transSeq(df):
    """
    get transcript protein sequence from downloaded
    ensembl library file:
    Homo_sapiens.GRCh38.pep.all.fa !!!

    ENSP protein identifier:
    encoded in CGI_info: 'CSQN=Missense|codon_pos=24201547-24201548-24201549|ref_codon_seq=CCC|aliases=ENSP0
0000442830|source=Ensembl'

    Args:
        panda dataframe
    """

    inputdata="/genomics/users/marta/genomes/GRCh38/Homo_sapiens.GRCh38.pep.all.noversion.fa" ###!!!!!!! ESSENTIAL WITHOUT THE VERSION
    ensembl_dict = SeqIO.index(inputdata, "fasta")

    current_var="" #set first mutation

    #Transcript ID
    for ind, row in df.iterrows(): # for each row
        if current_var != df['ID'][ind]: # variant differs to the previous one
            ls_extra=(df['Extra'][ind]).split(";") # split the extra column into subfields sep by ";"
            hgvsp=""
            for i in range(len(ls_extra)):
                if ls_extra[i].startswith("HGVSp=ENSP"):
                    hgvsp=ls_extra[i] # HGVSp is 10th field
            if hgvsp=="":
                print("\t### ERROR: No HGVSp was found for Mutation in",str(df['Location'][ind]))
            ensp_id=hgvsp[6:21] # ENSPid is 4letters + 11 numbers =total length 15

            # get seq for ENSP id
            if ensp_id in ensembl_dict:
                ensp_seq=str(ensembl_dict[ensp_id].seq)
            else:
                print("\t### ERROR: No Transcript was found for",ensp_id)
                break

            # SAVE SEQ
            df.at[ind,'Transcript_ID']= ensp_id
            df.at[ind,'Transcript_Seq']= ensp_seq
            # GET HGSV.p
            hgvsp=hgvsp.split('.',2)[2] # "HGVSp=ENSP00000239830.4:p.Gln279Leu" --> "Gln279Leu"
            df.at[ind,'AA_Change']= hgvsp # column AA_Change holds according AA change to transcript
            print(df.head)
            current_var=df['ID'][ind] # update current variant

    ensembl_dict.close()

    return df


def splitHGVSp(HGVSp):
        pattern = re.compile("([a-zA-Z]+)([0-9]+)([a-zA-Z*]+)")
        HGVSp_tp=pattern.match(HGVSp)
        if HGVSp_tp is None: # found matched pieces stored as tuple with 3 parts
            return False
        else:
            ref=seq1(HGVSp_tp.group(1))             # ref AA
            alt=seq1(HGVSp_tp.group(3))             # alternative AA
            pos=int(HGVSp_tp.group(2))-1   # nucleutide position that we will mutate (-1 cause python counts from 0)
            return (ref, alt, pos)


def apply_mut(df):
    """
    Mutate transcript seq
    """
    mutated_list=[]

    for ind, row in df.iterrows():
        if splitHGVSp(df.at[ind,'AA_Change']):
            ref, alt, mut_pos = splitHGVSp(df.at[ind,'AA_Change']) # split the HGVSp information stored in column AA_Change into ref, alt and pos

            Transcript_Seq=df['Transcript_Seq'][ind]

            if Transcript_Seq[mut_pos]==ref:  # if we see the expected AA (reference)
                Mutate_Seq = Transcript_Seq[:mut_pos] + alt + Transcript_Seq[mut_pos+1:] # change to alternative nucleotide
                print("\t\tMutation inserted successfully.")
                if len(Mutate_Seq)<9:
                    print("\t\tMutated Sequence is shorter than allowed and will be dropped.")
                    Mutate_Seq = "------------------"
            else:
                trans_id=df['Transcript_ID'][ind]
                print("\t#ERROR: ID",trans_id,"- Something went wrong. In Position", mut_pos,"we expect", ref,">", alt)
                print("\t\tInstead we see",Transcript_Seq[mut_pos])
                Mutate_Seq = "------------------"

        else:
            print("\t#ERROR: ID",df.at[ind,'ID'],"- Something went wrong. HGVSp does not fit pattern:",df.at[ind,'AA_Change'])
            print("\t\tMutation skipped.")
            Mutate_Seq = "------------------"

        mutated_list.append(Mutate_Seq)

    df['Mutate_Seq']=mutated_list

    return df


def write_fasta(df,outfile):
    """
    Write a fasta file for each patient with >identifier
    and the peptide seq around the mutation ()
    """
    outname=outfile

    fileMT = open(os.path.join(outpath,'{}_MTpeptide.fastq'.format(outname)), "w")
    fileWT = open(os.path.join(outpath,'{}_WTpeptide.fastq'.format(outname)), "w")

    for ind in df.index:
        if splitHGVSp(df.at[ind,'AA_Change']):
            fasta = create_fasta_input(df, ind)

            #write MT
            fileMT.write(fasta[0])
            fileMT.write(fasta[1])
            #write WT
            fileWT.write(fasta[0])
            fileWT.write(fasta[2])

    fileMT.close() #close open file
    fileWT.close() #close open file


def create_fasta_input(df, ind):
    """
    Return tuple with
    0. ID: take ID from input file
    1. MT: creating short peptide 7AA around mutation
    2. WT: creating short peptide nonmutated
    """
    # Create ID
    mut_id=">"+str(df['ID'][ind])+"\n"

    #Create peptide
    ref, alt, pos = splitHGVSp(df.at[ind,'AA_Change']) # split the HGVSp information stored in column AA_Change into ref, alt and pos
    s_pos=pos-9+1
    e_pos=pos+9
    if s_pos < 0:
        s_pos=0
        print("\t#WARNING: Peptide {} will be shorter because mutation close to transcript start.".format((df['ID'][ind])))
    if e_pos > len((df['Mutate_Seq'][ind])):
        e_pos=len((df['Mutate_Seq'][ind]))
        print("\t#WARNING: Peptide {} will be shorter because mutation close to transcript end.".format((df['ID'][ind])))

    mut_peptide = str((df['Mutate_Seq'][ind])[s_pos:e_pos]+"\n")
    wt_peptide = str((df['Transcript_Seq'][ind])[s_pos:e_pos]+"\n")

    return mut_id, mut_peptide, wt_peptide


def get_patientID(currentID):
    """
    function to read csv file to dictionary with sampleID as keys
    and patientID as value
    returns according PatientID
    Could also change to give  CombID as value if this is more useful
    """
    patientID=(os.path.basename(filepath))[0:5] #[0:5] depending on the dataset

    return patientID


def make_outdir(user_out):
    """
    Function to create output directory in
    a new folder for each patient ID
    """
    if user_out:
         outpath=user_out
    else:           #if user did not define outdir, put outfiels in workdir
        outpath=""
    patientID=(os.path.basename(filepath))[0:5] #[0:5] depending on the dataset

    ext=r'.vep'
    outname=re.sub(ext,'',(os.path.basename(filepath))) #drop file extension

    #check if folder for patient was created already, otherwise mkdir
    if not os.path.exists(os.path.join(outpath,patientID)):
        os.makedirs(os.path.join(outpath,patientID))

    outpath=os.path.join(outpath,patientID)

    return outpath, outname


if __name__ == "__main__":
    filepath = args.i

    # OUTDIR
    outpath,outname=make_outdir(args.o) #assign returned tuple

    # STDOUTDIR
    temp = sys.stdout                 # store original stdout object for later
    stdout=outname+'.out'
    sys.stdout = open(os.path.join(outpath,stdout), 'w')
    print("Command: python3 snv2pep_vepENSP.py -i",filepath,"-o",outpath,"-k",args.k)
    print("\nRun on",date.today(),"\n\n")

    # GET DATAFRAME FROM MAF
    df_snv = read_vcf(filepath)

    # GET TRANSCRIPTS
    print("#### I. OBTAINING TRANSCRIPTS\n")
    get_transSeq(df_snv)
    df_snv.dropna(subset = ["Transcript_ID"], inplace=True) #drop rows without Transcripts

    # INSERT MUTATION
    print("#### II. APPLYING MUTATIONS\n")
    apply_mut(df_snv)

    # SAVE OUTPUT
    print("#### III. WRITING TO OUTPUT\n")
    write_fasta(df_snv,outname)

    sys.stdout.close()
    sys.stdout = temp
    print("\n#### PROGRAM snv2pep.py finished! ##########\n#\n#\tOutput stored in:",outpath+outname+'_{WT,MT}peptide.fastq')
    print("#\tErrors and verbose were stored in:",os.path.join(outpath,stdout),"\n#")
    print("###########################################\n")


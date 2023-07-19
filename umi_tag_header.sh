#!/bin/bash

#########################################################################################################
# Copyright (c) 2023 CodeDepotIV
# Author  :  W. Ackerman
# Date    :  07/12/2023	
# License :  MIT License
#    last change: 07/12/2023
#
# PURPOSE:
#
# To tag FASTQ headers of paired reads with unique molecular identifiers (UMIs) without changing the 
# read sequences or Phred quality scores. 
#
# This is a simple shell script that processes two paired read gzipped FASTQ files, <read1.fastq.gz> and 
# <read2.fastq.gz>, specified by the -a and -b flags, respectively. The first 10 characters of the second 
# line (FASTA sequence) of each record in <read1.fastq.gz>, representing the UMI, are extracted and 
# appended it to the read name in the first line of the record. The processed records are then written 
# to a new file with the suffix " _processed.fastq.gz".
# 
# The code next extracts the UMIs from <read1.fastq.gz> and stores them in a temporary file called 
# "umis.txt". It then processes <read2.fastq.gz> by appending the corresponding UMI from umis.txt to 
# the read name in the first line of each record. The processed read 2 records are then written to a new 
# file with the suffix "_processed.fastq.gz". Finally, the "umis.txt" file is removed.
#
# This code was adapted from the "corall_batch.sh" file posted at Lexogen-Tools/corall_analysis. The code
# was developed with the assistance of Bing Chat, which provided valuable assistance with syntax and debugging.
#
# VERSIONS: v0.1
#
# TESTING:
#
# The script has been tested on paired-end read files created using the Lexogen CORALL Total RNA-Seq V2 kit
# and sequenced using the Illumina NovaSeq 6000 platform. It is NOT efficient, and at this stage, I am
# sacrificing efficiency for simplicity until the output has been tested thoroughly in downstream 
# applications.
#
# NOTE: The "umi.txt" file is now marked with the process ID so multiple batch submissions can be made without
# causing conflicts. 
#
# TODO: Needs better error handling, but works in real data cases.
# TODO: The code sometimes halts during execution of the read 2 processing step and gives a broken pipe 
#       error. This seems to be a problem external to the code itself, as it is irregular and environment 
#       dependent. 
# TODO: Code could easily be adapted for single-end reads as well.
#	
#########################################################################################################

# Usage: bash umi_tag_header.sh -a <read1.fastq.gz> -b <read2.fastq.gz>
# As executable: ./umi_tag_header.sh -a <read1.fastq.gz> -b <read2.fastq.gz>

usage() {
  echo;
  echo "PURPOSE: To tag FASTQ headers of paired reads with unique molecular identifiers (UMIs) without changing the read sequences or Phred quality scores.";
  echo;
  echo "Usage: bash $0 [-a <read1.fastq.gz>] [-b <read2.fastq.gz>]" >&2;
  echo;
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# parse command-line options
# script accepts two options, -a and -b, both of which require an argument
while getopts 'a:b:' flag; do
  case "${flag}" in
    a) r1="${OPTARG}" ;;
    b) r2="${OPTARG}" ;;
    *) echo "Usage: $0 [-a file] [-b file]" >&2
       exit 1 ;;
  esac
done

# define output file names
output_file_r1="${r1%.fastq.gz}_processed.fastq.gz"
output_file_r2="${r2%.fastq.gz}_processed.fastq.gz"

# append process ID in the $$ variable to make unique name
umis_file="umis_${$}.txt" 
echo "Temporary UMI file name: $umis_file"

echo "Processing read 1..."
# Process read 1
zcat $r1 | awk '{ 
    # decompress <read1.fastq.gz>
    if (NR % 4 == 1) {
        # parse FASTQ header
        # first field of the current line ($1) assigned to rd_name 
        # second field ($2) assigned to rd_info
        rd_name=$1
        rd_info=$2
    } else if (NR % 4 == 2) {
        # parse FASTA line of FASTQ
        # UMI abstracted from first 10 bp of FASTA  
        umi=substr($0, 1, 10)
        # UMI appended to rd_name in UMI-tools-friendly format 
        printf("%s_%s %s\n", rd_name, umi, rd_info)
        print
    } else {
        print
    }
# compress and write to output_file_r1    
}' | gzip > $output_file_r1
echo "Done processing read 1."

echo "Extracting UMIs from read 1..."
# Extract UMIs from read 1
zcat $output_file_r1 | awk -v umis_file="$umis_file" '{
    if (NR % 4 == 1) {
        # process FASTQ headers
        # split at "_", second element (arr[2]) is UMI
        split($1, arr, "_")
        rd_name=arr[1]
        umi=arr[2]
        printf("%s\t%s\n", rd_name, umi)
    }
}' > $umis_file
echo "UMI extraction complete."

echo "Processing read 2..."
# Process read 2        
                                
zcat $r2 | awk -v umis_file="$umis_file" '{    
# decompress <read2.fastq.gz>
# -v option sets the awk variable umis_file to "umis.txt"
          
    if (NR == FNR) {  
        # (NR == FNR) when first input file, "umis.txt", is processed	
        # second input is stdout from <read2.fastq.gz>
        # creates an associative array rd_name2umi, where keys=read names, values=UMIs in "umis.txt"                                      	
        rd_name2umi[$1] = $2	                            
        next                 
    }                                                 
    if (FNR == 1) {
        # make sure array gets created
        print "Associative array created." > "/dev/stderr"
    }					 
    if (FNR % 4 == 1) {
        # parse FASTQ header
        if (!rd_name2umi[$1]) {  
            # if the read name not found in rd_name2umi array, skip                          
            next				 
        } else {
            # append corresponding UMI to read name				
            umi=rd_name2umi[$1]		                       
            printf("%s_%s %s\n", $1, umi, $2)	           
        }				
    } else {
        print
    }
}' $umis_file - | gzip > $output_file_r2   
# awk output piped to gzip command, writes compressed file to $output_file_r2  
                 
echo "Done processing read 2."                            	                                                         
rm $umis_file # removes temp file "umis.txt"

# UMI Tag Header

This shell script tags FASTQ headers of paired reads with unique molecular identifiers (UMIs) without changing the read sequences or Phred quality scores.

## Usage

This script is designed to be used in a Linux environment. To run the script, issue the following command:

`bash umi_tag_header.sh -a <read1.fastq.gz> -b <read2.fastq.gz>`

Alternatively, you can make the script executable and run it directly:

`chmod +x umi_tag_header.sh ./umi_tag_header.sh -a <read1.fastq.gz> -b <read2.fastq.gz>`

The `-a` and `-b` options are used to specify the input files. The script will generate two output files with the suffix `_processed.fastq.gz`.

## Testing 

This shell script has been tested and confirmed to work on Ubuntu 20.04 and CentOS 7. To test the script, download the `subA.fq.gz` and `subB.fq.gz` files in the **test_data** folder to a suitable directory and execute:

`bash umi_tag_header.sh - a subA.fq.gz -b subB.fq.gz`

## Dependencies

This script requires `zcat`, `awk`, and `gzip` to be installed and available in your `PATH`.

## Reference

Pending.

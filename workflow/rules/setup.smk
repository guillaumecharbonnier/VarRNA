import sys, os
import pandas as pd
from snakemake.utils import min_version

min_version("6.0")

###### Config file and sample sheet #####
configfile: "../config/config.yaml"
rna_samples = pd.read_csv(config["samples"], comment="#").set_index("sample", drop=False)

##### Wildcard constraints #####
wildcard_constraints:
    sample="|".join(rna_samples.index),
    chrom = "|".join(["chr"+str(x) for x in range(1,23)] + ["chrX", "chrY"]),
    sex = "|".join(["male", "female"])

##### Helper functions #####
def get_rna_sample_bams(wildcards):
    """Get input RNA BAM file of a given sample."""
    file_path = rna_samples.loc[wildcards.sample, "file_path"]
    if pd.notna(file_path) and file_path != "":
        return file_path
    else:
        return []

def has_fastq_input(wildcards):
    """Check if sample has FASTQ input."""
    fastq_1 = rna_samples.loc[wildcards.sample, "fastq_1"]
    fastq_2 = rna_samples.loc[wildcards.sample, "fastq_2"]
    return pd.notna(fastq_1) and pd.notna(fastq_2) and fastq_1 != "" and fastq_2 != ""

def get_fastq_r1(wildcards):
    """Get FASTQ R1 file path."""
    fastq_1 = rna_samples.loc[wildcards.sample, "fastq_1"]
    if pd.notna(fastq_1) and fastq_1 != "":
        return fastq_1
    else:
        # Return empty list to signal this rule should not be used
        return []

def get_fastq_r2(wildcards):
    """Get FASTQ R2 file path."""
    fastq_2 = rna_samples.loc[wildcards.sample, "fastq_2"]
    if pd.notna(fastq_2) and fastq_2 != "":
        return fastq_2
    else:
        # Return empty list to signal this rule should not be used
        return []

def get_input_bam_for_processing(wildcards):
    """Get the BAM file for processing - either from file_path or from STAR alignment."""
    if has_fastq_input(wildcards):
        return f"../results/{wildcards.sample}/BAMs/{wildcards.sample}.Aligned.sortedByCoord.out.bam"
    else:
        return rna_samples.loc[wildcards.sample, "file_path"]

def get_sample_sex(wildcards):
    """Get the sex of a given sample."""
    sex = rna_samples.loc[wildcards.sample, "sex"]
    return(sex)

def get_chroms():
    """Get list of chromosomes to paralellize variant calling."""
    return(["chr"+str(x) for x in range(1,23)] + ["chrX", "chrY"])


# def get_haplotype_caller_params(wildcards):
#     """Get all parameters for GATK HaplotypeCaller."""
#     return(
#         config["params"]["gatk"]["HaplotypeCaller"]["misc"] + 
#         " -L {chrom} ".format(chrom=wildcards.chrom) + 
#         config["params"]["gatk"]["HaplotypeCaller"]["annotations"]
#     )

def get_bcftools_query_values():
    """Get all values to query and format them for bcftools query."""
    return(config["querying"]["default"].replace(" ", "\\t"))

def get_all_inputs():
    """Get input files for rule all."""
    return(
        expand("../results/{sample}/Predictions/{sample}.annotated_predictions.csv", sample=rna_samples.index),
    )

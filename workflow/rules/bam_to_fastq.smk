ruleorder: symlink_fastq_for_salmon > bam_to_fastq

rule bam_to_fastq:
    input:
        get_rna_sample_bams,
    output:
        fastq1=temp("../results/{sample}/FASTQs/{sample}.R1.fastq.gz"),
        fastq2=temp("../results/{sample}/FASTQs/{sample}.R2.fastq.gz"),
        singleton=temp("../results/{sample}/FASTQs/{sample}.singleton.fastq.gz"),
        ambiguous=temp("../results/{sample}/FASTQs/{sample}.ambiguous.fastq.gz"),
    log:
        "logs/picard/sam_to_fastq/{sample}.log",
    threads: 20
    shell:
        "samtools sort -n --threads 10 {input} | samtools fastq --threads 10 -c 6 -1 {output.fastq1} -2 {output.fastq2} -s {output.singleton} -0 {output.ambiguous} -"

rule symlink_fastq_for_salmon:
    input:
        r1=get_fastq_r1,
        r2=get_fastq_r2,
    output:
        fastq1=temp("../results/{sample}/FASTQs/{sample}.R1.fastq.gz"),
        fastq2=temp("../results/{sample}/FASTQs/{sample}.R2.fastq.gz"),
    log:
        "logs/symlink_fastq/{sample}.log",
    threads: 1
    shell:
        "ln -sf $(realpath {input.r1}) {output.fastq1}; "
        "ln -sf $(realpath {input.r2}) {output.fastq2}"
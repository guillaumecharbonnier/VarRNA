rule star_first_pass:
    input:
        r1=get_fastq_r1,
        r2=get_fastq_r2,
        genome_index=config["dependencies"]["star_index"],
    output:
        bam=temp("../results/{sample}/BAMs/{sample}.temp.Aligned.sortedByCoord.out.bam"),
        sj=temp("../results/{sample}/BAMs/{sample}.temp.SJ.out.tab"),
    log:
        "logs/star/first_pass/{sample}.log",
    params:
        star_bin=config["dependencies"]["star"],
        prefix="../results/{sample}/BAMs/{sample}.temp.",
    threads: config["params"]["star"]["threads"]
    shell:
        "{params.star_bin} "
        "--runThreadN {threads} "
        "--genomeDir {input.genome_index} "
        "--readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat "
        "--outSAMtype BAM SortedByCoordinate "
        "--outFileNamePrefix {params.prefix} "
        "--outSAMunmapped Within "
        "> {log} 2>&1"

rule star_second_pass:
    input:
        r1=get_fastq_r1,
        r2=get_fastq_r2,
        genome_index=config["dependencies"]["star_index"],
        sj="../results/{sample}/BAMs/{sample}.temp.SJ.out.tab",
    output:
        bam="../results/{sample}/BAMs/{sample}.Aligned.sortedByCoord.out.bam",
    log:
        "logs/star/second_pass/{sample}.log",
    params:
        star_bin=config["dependencies"]["star"],
        prefix="../results/{sample}/BAMs/{sample}.",
    threads: config["params"]["star"]["threads"]
    shell:
        "{params.star_bin} "
        "--runThreadN {threads} "
        "--genomeDir {input.genome_index} "
        "--readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat "
        "--sjdbFileChrStartEnd {input.sj} "
        "--outSAMtype BAM SortedByCoordinate "
        "--outFileNamePrefix {params.prefix} "
        "--outSAMunmapped Within "
        "> {log} 2>&1"

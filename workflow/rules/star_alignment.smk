# Note: STAR alignment rules assume gzipped FASTQ files (.fastq.gz or .fq.gz)
# For uncompressed FASTQ files, remove the '--readFilesCommand zcat' parameter

rule build_star_index:
    input:
        fasta=config["reference"]["fasta"],
        gtf=config["reference"]["gtf"],
    output:
        index_dir=directory(config["dependencies"]["star_index"]),
        sa=config["dependencies"]["star_index"] + "SA",
    log:
        "logs/star/build_index.log",
    params:
        sjdb_overhang=config["params"]["star"].get("sjdb_overhang", 160),
    threads: config["params"]["star"]["threads"]
    shell:
        "STAR --runMode genomeGenerate "
        "--runThreadN {threads} "
        "--genomeDir {output.index_dir} "
        "--genomeFastaFiles {input.fasta} "
        "--sjdbGTFfile {input.gtf} "
        "--sjdbOverhang {params.sjdb_overhang} "
        "> {log} 2>&1"

rule star_first_pass:
    input:
        r1=get_fastq_r1,
        r2=get_fastq_r2,
        genome_index=config["dependencies"]["star_index"] + "SA",
    output:
        bam=temp("../results/{sample}/BAMs/{sample}.temp.Aligned.sortedByCoord.out.bam"),
        sj=temp("../results/{sample}/BAMs/{sample}.temp.SJ.out.tab"),
    log:
        "logs/star/first_pass/{sample}.log",
    params:
        prefix="../results/{sample}/BAMs/{sample}.temp.",
        genome_dir=config["dependencies"]["star_index"],
        tmp_dir=config["params"]["star"].get("tmp_dir", "/tmp"),
    threads: config["params"]["star"]["threads"]
    shell:
        "STAR "
        "--runThreadN {threads} "
        "--genomeDir {params.genome_dir} "
        "--readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat "
        "--outSAMtype BAM SortedByCoordinate "
        "--outFileNamePrefix {params.prefix} "
        "--outSAMunmapped Within "
        "--outTmpDir {params.tmp_dir}/_STARtmp_{wildcards.sample} "
        "> {log} 2>&1 && rm -rf {params.tmp_dir}/_STARtmp_{wildcards.sample}"

rule star_second_pass:
    input:
        r1=get_fastq_r1,
        r2=get_fastq_r2,
        genome_index=config["dependencies"]["star_index"] + "SA",
        sj="../results/{sample}/BAMs/{sample}.temp.SJ.out.tab",
    output:
        bam="../results/{sample}/BAMs/{sample}.Aligned.sortedByCoord.out.bam",
    log:
        "logs/star/second_pass/{sample}.log",
    params:
        prefix="../results/{sample}/BAMs/{sample}.",
        genome_dir=config["dependencies"]["star_index"],
        tmp_dir=config["params"]["star"].get("tmp_dir", "/tmp"),
    threads: config["params"]["star"]["threads"]
    shell:
        "STAR "
        "--runThreadN {threads} "
        "--genomeDir {params.genome_dir} "
        "--readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat "
        "--sjdbFileChrStartEnd {input.sj} "
        "--outSAMtype BAM SortedByCoordinate "
        "--outFileNamePrefix {params.prefix} "
        "--outSAMunmapped Within "
        "--outTmpDir {params.tmp_dir}/_STARtmp_{wildcards.sample} "
        "> {log} 2>&1 && rm -rf {params.tmp_dir}/_STARtmp_{wildcards.sample}"

# Note: STAR alignment rules assume gzipped FASTQ files (.fastq.gz or .fq.gz)
# For uncompressed FASTQ files, remove the '--readFilesCommand zcat' parameter

rule download_star:
    output:
        star_bin=config["dependencies"]["star"],
    log:
        "logs/star/download_star.log",
    params:
        star_version="STAR_2.7.10b_alpha_230301",
        download_dir="../dependencies/",
    threads: 1
    shell:
        "wget https://github.com/alexdobin/STAR/releases/download/{params.star_version}/{params.star_version}_Linux_x86_64_static.zip -P {params.download_dir} > {log} 2>&1 && "
        "unzip -o {params.download_dir}/{params.star_version}_Linux_x86_64_static.zip -d {params.download_dir} >> {log} 2>&1 && "
        "mv {params.download_dir}/{params.star_version}_Linux_x86_64_static/STAR {output.star_bin} >> {log} 2>&1 && "
        "chmod +x {output.star_bin}"

rule build_star_index:
    input:
        fasta=config["reference"]["fasta"],
        gtf=config["reference"]["gtf"],
        star_bin=config["dependencies"]["star"],
    output:
        index_dir=directory(config["dependencies"]["star_index"]),
        sa=config["dependencies"]["star_index"] + "SA",
    log:
        "logs/star/build_index.log",
    params:
        sjdb_overhang=config["params"]["star"].get("sjdb_overhang", 160),
    threads: config["params"]["star"]["threads"]
    shell:
        "{input.star_bin} --runMode genomeGenerate "
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
        star_bin=config["dependencies"]["star"],
    output:
        bam=temp("../results/{sample}/BAMs/{sample}.temp.Aligned.sortedByCoord.out.bam"),
        sj=temp("../results/{sample}/BAMs/{sample}.temp.SJ.out.tab"),
    log:
        "logs/star/first_pass/{sample}.log",
    params:
        star_bin=config["dependencies"]["star"],
        prefix="../results/{sample}/BAMs/{sample}.temp.",
        genome_dir=config["dependencies"]["star_index"],
    threads: config["params"]["star"]["threads"]
    shell:
        "{params.star_bin} "
        "--runThreadN {threads} "
        "--genomeDir {params.genome_dir} "
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
        genome_index=config["dependencies"]["star_index"] + "SA",
        star_bin=config["dependencies"]["star"],
        sj="../results/{sample}/BAMs/{sample}.temp.SJ.out.tab",
    output:
        bam="../results/{sample}/BAMs/{sample}.Aligned.sortedByCoord.out.bam",
    log:
        "logs/star/second_pass/{sample}.log",
    params:
        star_bin=config["dependencies"]["star"],
        prefix="../results/{sample}/BAMs/{sample}.",
        genome_dir=config["dependencies"]["star_index"],
    threads: config["params"]["star"]["threads"]
    shell:
        "{params.star_bin} "
        "--runThreadN {threads} "
        "--genomeDir {params.genome_dir} "
        "--readFilesIn {input.r1} {input.r2} "
        "--readFilesCommand zcat "
        "--sjdbFileChrStartEnd {input.sj} "
        "--outSAMtype BAM SortedByCoordinate "
        "--outFileNamePrefix {params.prefix} "
        "--outSAMunmapped Within "
        "> {log} 2>&1"

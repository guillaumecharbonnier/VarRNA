rule build_salmon_index:
    input:
        transcriptome=config["reference"]["transcriptome"],
    output:
        directory(config["dependencies"]["salmon_index"]),
    log:
        "logs/salmon/build_index.log",
    threads: 10
    shell:
        "salmon index -t {input.transcriptome} -i {output} -p {threads} 2> {log}"

rule salmon_quant_reads:
    input:
        r1="../results/{sample}/FASTQs/{sample}.R1.fastq.gz",
        r2="../results/{sample}/FASTQs/{sample}.R2.fastq.gz",
        index=config["dependencies"]["salmon_index"],
    output:
        quant="../results/{sample}/salmon/quant.sf",
        lib="../results/{sample}/salmon/lib_format_counts.json",
    log:
        "logs/salmon/{sample}.log",
    params:
        libtype=config["params"]["salmon"]["libtype"],
    threads: 10
    shell:
        "salmon quant --threads 10 -l {params.libtype} -o ../results/{wildcards.sample}/salmon/ -i {input.index} -1 {input.r1} -2 {input.r2}"

# rule modify_names:
#    input:
#        quant="../results/{sample}/salmon/quant.sf",
#        gentrome=config["reference"]["gentrome"],
#    output:
#        "../results/{sample}/salmon/quant.sf.orig",
#    log:
#        "logs/salmon/modify_names.{sample}.log",
#    shell:
#        "scripts/map_ids.pl {input.quant} {input.gentrome}"
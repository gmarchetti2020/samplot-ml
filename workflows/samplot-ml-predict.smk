## General TODOs
# * provide example scripts on how to programmaticaly create sample: file pairs
#   in the config yaml.
# * or make a rule that looks at the RG tags to get sample names from list of bams

import os
import functools
from glob import glob
from config_utils import Conf


## Setup
################################################################################
configfile: 'conf/samplot-ml-predict.yaml'
conf = Conf(config)

## Rules
################################################################################
rule All:
    input:
        expand(f'{conf.outdir}/samplot-ml-results/{{sample}}-samplot-ml.vcf.gz',
               sample=conf.samples)
    

fasta_in=config["fasta"]["file"]
fai_in=config["fai"]["file"]

# This sample rule copies the reference genomes from data to output directory.
# You can change it to download from your source, e.g. via wget or ftp.
rule GetReference:
    input:
        fasta=fasta_in, #"data/GRCh38_full_analysis_set_plus_decoy_hla.fa",
        fai=fai_in #"data/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai"
    output:
        fasta = f'{conf.outdir}/'+fasta_in.rsplit('/')[-1], #"output/GRCh38_full_analysis_set_plus_decoy_hla.fa",
        fai = f'{conf.outdir}/'+fai_in.rsplit('/')[-1] #"output/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai"
    resources:
        disk_mb=100000
    run:
        shell("cp {input.fasta} {output.fasta}")
        shell("cp {input.fai} {output.fai}")
    

vcf_in=config["vcf"]["file"]

# This sample rule copies the starting annotation file from data to output directory.
# You can change it to download from your source, e.g. via wget or ftp.
rule GetBaseVCF:
    input:
        vcf_in
    output:
        f'{conf.outdir}/'+vcf_in.rsplit('/')[-1]
    #run:
    #    shell(conf.vcf.get_cmd())
    shell:
        "cp {input} {output}"


rule GetDelRegions:
    """
    Get a sample's del regions from the vcf in bed format
    """
    input:
        conf.vcf.output
    output:
        f'{conf.outdir}/bed/{{sample}}-del-regions.bed'
    conda:
        'envs/samplot.yaml'
    resources:
        #machine_type="n1-standard-8",
        mem_mb=4000,
        disk_mb=10000
    shell:
        f"""
        mkdir -p {conf.outdir}/bed
        bash scripts/get_del_regions.sh {{input}} {{wildcards.sample}} > {{output}}
        """
    


def get_images(rule, wildcards):
    """
    Return list of output images from the GenerateImages/CropImages checkpoints
    """
    # gets output of the checkpoint (a directory) and re-evals workflow DAG 
    if rule == "GenerateImages":
        image_dir = checkpoints.GenerateImages.get(sample=wildcards.sample).output[0]
    elif rule == "CropImages":
        image_dir = checkpoints.CropImages.get(sample=wildcards.sample).output[0]
    else:
        raise ValueError(f'Unknown argument for rule: {rule}.'
                             'Must be "GenerateImages" or "CropImages"')
    return glob(f'{image_dir}/*.png')


rule GenerateImages:
    """
    Images from del regions for a given sample.
    """
    threads: workflow.cores
    input:
        # bam/ file: from config. could be a url
        # therefore will not be tracked by snakemake
        fasta = conf.fasta.output,
        fai = conf.fai.output,
        regions = rules.GetDelRegions.output,
        # samplot requires an index file for each sample. 
        # I could not figure out how to pass both sample and index via wildcards
        bam=config["samples"]["HG03687"], #"data/HG03687.final.cram",
        bai=config["samples_idx"]["HG03687"] #"data/HG03687.final.cram.crai"
        #bam = lambda wildcards: conf.alignments[wildcards.sample],
    output:
        directory(f'{conf.outdir}/img/{{sample}}')
    params:
        #cannot pass the bam as a parameter - it won't be copied to the container.
        #bam = lambda wildcards: conf.alignments[wildcards.sample]
    conda:
        'envs/samplot.yaml'
    resources:
        machine_type="n1-standard-8",
        mem_mb=30000,
        disk_mb=100000
    shell:
        # TODO put the gen_img.sh script into a function in images_from_regions.sh
        f"""
        wget https://github.com/brentp/gargs/releases/download/v0.3.9/gargs_linux -O ./gargs; \\
        chmod a+x ./gargs; \\
        mkdir -p {{output}}; \\
        bash scripts/images_from_regions.sh \\
            --gargs-bin ./gargs \\
            --fasta {{input.fasta}} \\
            --regions {{input.regions}} \\
            --bam {{input.bam}} \\
            --outdir {{output}} \\
            --delimiter {conf.delimiter} \\
            --processes {{threads}}
        """
    

rule CropImages:
    """
    Crop axes and text from images to prepare for samplot-ml input
    """
    threads: workflow.cores
    input:
        imgs = directory(rules.GenerateImages.output)
        # imgs = functools.partial(get_images, 'GenerateImages')
    output:
        directory(f'{conf.outdir}/crop/{{sample}}')

    resources:
        machine_type="n1-standard-8",
        mem_mb=30000,
        disk_mb=100000
    conda:
        'envs/samplot.yaml'
    shell:
        f"""
        wget https://github.com/brentp/gargs/releases/download/v0.3.9/gargs_linux -O ./gargs; \\
        chmod a+x ./gargs; \\
        mkdir -p {{output}}; \\
        bash scripts/crop.sh -i {{input.imgs}} \\
                             -o {{output}} \\
                             -p {{threads}} \\
                             -g ./gargs
        """
    
rule CreateImageList:
    """
    Samplot-ml needs list of input images. This rule takes the list
    of a sample's cropped images and puts them in a text file.
    """
    input:
        #functools.partial(get_images, 'CropImages')
        directory(rules.CropImages.output)
    output:
        f'{conf.outdir}/{{sample}}-cropped-imgs.txt'
    shell:
        "ls {input}/*.png > {output}"
    #run:
    #    with open(output[0], 'w') as out:
            # for image_file in input:
    #        for image_file in glob(f'{conf.outdir}/crop/{wildcards.sample}/*.png'):
    #            out.write(f'{image_file}\n')


rule PredictImages:
    """
    Feed images into samplot-ml to get a bed file of predictions.
    Prediction format (tab separated):
        - chrm start end p_ref p_het p_alt
    """
    threads: workflow.cores
    input:
        f'{conf.outdir}/{{sample}}-cropped-imgs.txt'
    output:
        f'{conf.outdir}/{{sample}}-predictions.bed'
    resources:
        machine_type="n1-standard-8",
        mem_mb=30000,
        disk_mb=100000
    conda:
        'envs/tensorflow.yaml'
    shell:
        """
        python scripts/predict.py \\
            --image-list {input} \\
            --delimiter {conf.delimiter} \\
            --processes {threads} \\
            --batch-size {threads} \\
            --model-path saved_models/samplot-ml.h5 \\
        > {output}
        """
    


rule AnnotateVCF:
    input:
        vcf = conf.vcf.output,
        bed = f'{conf.outdir}/{{sample}}-predictions.bed'
    output:
        f'{conf.outdir}/samplot-ml-results/{{sample}}-samplot-ml.vcf.gz'
    resources:
        #machine_type="n1-standard-8",
        mem_mb=30000,
        disk_mb=100000
    conda:
        'envs/samplot.yaml'
    shell:
        """
        bcftools view -s {wildcards.sample} {input.vcf} |
        python scripts/annotate.py {input.bed} {wildcards.sample} |
        bgzip -c > {output}
        """
        
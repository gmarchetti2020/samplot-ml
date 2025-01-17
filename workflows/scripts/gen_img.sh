#!/bin/env bash
set -eu

while (( "$#" )); do
    case "$1" in
        -c|--chrom)
            chrom=$2
            shift 2;;
        -s|--start)
            start=$2
            shift 2;;
        -e|--end)
            end=$2
            shift 2;;
        -n|--sample)
            sample=$2
            shift 2;;
        -g|--genotype)
            genotype=$2
            shift 2;;
        -m|--min-mqual)
            min_mq=$2
            shift 2;;
        -f|--fasta)
            fasta=$2
            shift 2;;
        -b|--bam)
            bam=$2
            shift 2;;
        -d|--delimiter)
            delimiter=$2
            shift 2;;
        -o|--outdir)
            outdir=$2
            shift 2;;
        --) # end argument parsing
            shift
            break;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1;;
    esac
done

# out=$outdir/${chrom}_${end}_${sample}_${genotype}.png
out=$outdir/$(echo "$chrom $start $end $sample $genotype.png" | tr ' ' $delimiter)
echo $out
svlen=$(($end-$start))
# window=$(python -c "print(int($svlen * 0.5))")

if [[ $svlen -gt 5000 ]]; then
    samplot plot \
        --zoom 1000 \
        -c $chrom -s $start -e $end \
        -q $min_mq \
        -t DEL \
        -b $bam \
        -r $fasta \
        -o $out
else
    samplot plot \
        -c $chrom -s $start -e $end \
        -q $min_mq \
        -t DEL \
        -b $bam \
        -r $fasta \
        -o $out
fi

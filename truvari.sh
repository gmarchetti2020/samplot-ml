lumpy_vcf=HG002-smoove.genotyped.vcf.gz
fasta=/scratch/Shares/layer/ref/hs37-1kg/human_g1k_v37.20.fasta

#truvari –s 300 –S 270 –b HG002_SVs_Tier1_v0.6.DEL.vcf.gz –c $lumpy_vcf –o eval-no-support –passonly –pctsim = 0 –r 20 –giabreport –f $fasta –no-ref –includebed HG002_SVs_Tier1_v0.6.bed –O 0.6


out_dir=duphold_comp
rm -rf $out_dir

#truvari \
#~/src/truvari.brentp/truvari.py \

#vcf=HG002-smoove.genotyped.ml.gt_0.9.vcf.gz
#vcf=HG002-smoove.genotyped.ml.gt_0.8.vcf.gz
#vcf=HG002-smoove.genotyped.DEL.DHFFC_lt_0.7.vcf.gz 
#vcf=HG002-smoove.genotyped.ml.gt_0.5.vcf.gz
vcf=HG002-smoove.genotyped.ml.het_p_alt_gt_0.5.vcf.gz
truvari \
    -b HG002_SVs_Tier1_v0.6.DEL.vcf.gz \
    -c $vcf \
    -o duphold_comp \
    --reference /scratch/Shares/layer/ref/hs37-1kg/human_g1k_v37.20.fasta \
    --pctsim 0 \
    --sizemax 15000000 \
    --sizemin 300 --sizefilt 270 \
    --includebed HG002_SVs_Tier1_v0.6.bed \
    --pctov 0.6 \
    --giabreport \
    --refdist 20 \
    --no-ref a

    #--passonly \


#truvari.py --sizemax 15000000 -s 300 -S 270 -b HG002_SVs_Tier1_v0.6.DEL.vcf.gz -c $dupholded_vcf -o $out \
   #--passonly --pctsim=0  -r 20 --giabreport -f $fasta --no-ref --includebed HG002_SVs_Tier1_v0.6.bed -O 0.6
#

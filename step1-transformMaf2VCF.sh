#! /usr/bin/env bash
# Transform maf file to vcf file using maf2vcf.pl script and 
# delete information of normal samples in order to transform tumor-normal pair VCF files to single-sample VCF files

echo --------------------------
echo -- Transform maf to vcf --
echo --------------------------

# load arguments
source $(pwd)/inputArgs.txt

# check if the maf file exisits
if [ ! -n $maffiles ]; then
    echo -e "\033[31m Error: there is no maf file, please check your input. \033[0m"
    exit 1
fi

# if have multiple maf files, an error will be given and exit
i=0

for maffile in $maffiles
do
    let i+=1
done

if [ $i -gt 1 ]; then
    echo -e "\033[31m Error: there are multiple maf files, please select only one of them. \033[0m"
    exit 1
fi

# set output dir of maf2vcf
tn=$OUTPUT/tumor_normal_pair
if [ ! -d "$tn" ]; then
    echo  -e "\033[33m The tumor_normal_pair directory does not exist under $OUTPUT, we will create it. \033[0m" 
    mkdir -p $tn
fi  
# transform
echo "transforming..."
$maf2vcf --input-maf $maffiles --output-dir $tn --ref-fasta $PATH_FASTA --per-tn-vcfs
echo "transform complete."

echo "delete information column of normal samples..."
sgvcf=$OUTPUT/single_vcfs
if [ ! -d "$sgvcf" ]; then
    echo  -e "\033[33m The single_vcfs directory does not exist under $OUTPUT, we will create it. \033[0m" 
    mkdir -p $sgvcf
fi  
    
for vcf in $(ls $tn | grep "vs")
do
    #sample=$(echo $vcf | cut -b 1-15)
    sample=$(echo $vcf | sed -E 's/^([^\s]{1,})_vs.*/\1/')
    printf "\rprocess %s .." $sample
    cat $tn/$vcf | awk 'BEGIN{FS="\t";OFS="\t"}{if($1 ~ /^##]/){print $0}else{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}}' > $sgvcf/$sample".vcf"
done

echo 
echo "transform step finished."


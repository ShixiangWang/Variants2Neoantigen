#! /usr/bin/env bash
# Delete information of normal samples in order to transform tumor-normal pair VCF files to single-sample VCF files
# Author: Shixiang Wang <wangshx@shanghaitech.edu.cn>

inputVCFdir=~/ProjectsManager/data/luad_mutect_vcf/ # directory path of tumor-normal pair VCF files
outputVCFdir=~/ProjectsManager/data/luad_mutect_singleVCF/ # directory path of single tumor VCF files

if [ ! -d $outputVCFdir ]; then
    echo "The output directory does not exist, we will create it."
    mkdir -p $outputVCFdir
fi    

filenames=$(ls "$inputVCFdir" | grep -E '^TCGA-.*vcf')

for filename in $filenames
do
    echo "Processing $filename"
    newName=$(echo $filename | cut -b 1-15)".vcf"
    cat $inputVCFdir/$filename | awk 'BEGIN{FS="\t";OFS="\t"}{if($1 ~ /^##]/){print $0}else{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}}' > $outputVCFdir/$newName
done

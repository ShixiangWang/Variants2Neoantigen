#!/usr/bin/env bash
# run VEP annotation and pVACseq in a parallel way

echo --------------------------------------
echo -- Generate neoantigens parallelly  --
echo --------------------------------------

# load arguments
source $(pwd)/inputArgs.txt

###################<<<<<<<<<<<<<<<<<<<<<< Begin
sgvcf=$OUTPUT/single_vcfs                    # input single vcf file directory
pvacseqRes=$OUTPUT/pvacseqResults            # output file directory of pvacseq

# make sure the output dir exisit, otherwise create it
if [ ! -d "$pvacseqRes" ]; then
    echo  -e "\033[33m The pvacseq results directory does not exist under $OUTPUT, we will create it. \033[0m" 
    mkdir -p $pvacseqRes
fi   

# get all input vcf filenames 
filenames=$(ls "$sgvcf" | grep -E '.*\.vcf$')
# mkdir cache data which annotated and filterd thus used for pVACseq
annotated_dir=$pvacseqRes/annot_dir
mkdir -p $annotated_dir

echo -e "\033[32m Begin of VEP and pVACseq pipeline... \033[0m"

runPVACseq() {
    filename=$1
    
    # load arguments
    source $(pwd)/inputArgs.txt
    # load path again in case global variable not pass in correctly
    sgvcf=$OUTPUT/single_vcfs                    # input single vcf file directory
    pvacseqRes=$OUTPUT/pvacseqResults            # output file directory of pvacseq
    annotated_dir=$pvacseqRes/annot_dir

    #sampleID=$(echo $filename | cut -b 1-15)
    sampleID=$(echo $filename | sed -E 's/(.*)\.vcf$/\1/')
    printf "\rprocess %s ..\n" $sampleID
    
    # step 1: annotate every sample with VEP, and filter (ONLY "PASS" can be used in downstream)
    $vep_run --input_file $sgvcf/$filename --format vcf --output_file stdout \
             --vcf --symbol --terms SO --plugin Downstream --plugin Wildtype --dir_plugins $PATH_VEP_PLUGINS --assembly $assembly_version --fasta $PATH_FASTA --dir_cache $CACHE_VEP --offline --pick --force_overwrite \
             > $annotated_dir/$sampleID"_annotated_filterd.vcf"
             #| $vep_filter --format vcf --force_overwrite --filter "(FILTER is PASS)" --output_file $annotated_dir/$sampleID"_annotated_filterd.vcf"
    
    
    # step 2: run pvacseq
    source activate $py_env
    res_dir=$pvacseqRes/"res_"$sampleID    
    # a directory can only store one sample result !!!!!!!!
    pvacseq run \
        $annotated_dir/$sampleID"_annotated_filterd.vcf" \
        $sampleID \
        $(grep $sampleID $PATH_HLA | awk '{print $2}') \
        $method $res_dir \
        -e $epitope_len \
        -a sample_name \
        -d 500
        --iedb-install-directory $PATH_MHC 
       
    source deactivate $py_env    
}

export -f runPVACseq

# run
echo $filenames | sed 's/\s/\n/g' | parallel  runPVACseq

echo -e "\033[32m End of VEP and pVACseq pipeline... \033[0m"
###################>>>>>>>>>>>>>>>>>>>>>>> End



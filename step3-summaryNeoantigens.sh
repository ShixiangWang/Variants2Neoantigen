#! /usr/bin/env bash
# Merge neoantigen files and transform the data then compute Neoantigen Quality

echo ---------------------------------
echo -- Compute Neoantigen Quality  --
echo ---------------------------------

# load arguments
source $(pwd)/inputArgs.txt

###########<<<<<< Summary all result data processed by pVACseq tool
input_dir=$OUTPUT/pvacseqResults
neo_dir=$OUTPUT/neoantigens

# make sure the neo dir exisit, otherwise create it
if [ ! -d $neo_dir ]; then
    echo  -e "\033[33m The neoantigens result directory does not exist under $OUTPUT, we will create it. \033[0m" 
    mkdir -p $neo_dir
fi   

final_dir=$neo_dir/final_neoantigens
mkdir -p $final_dir

# get all final neoantigens of listed samples in input directory
neodirs=$(ls $input_dir | grep "res")

for neodir in $neodirs
do
    #sample=$(echo $neodir | cut -b 5-19) 
    sample=$(echo $neodir | sed -E 's/res_(.*)/\1/') 
    neofile=$input_dir/$neodir/"MHC_Class_I"/$sample".final.tsv"
    if [ -f $neofile ]; then
        cp $neofile $final_dir
        printf "\rcopy %s to $final_dir ..." $neofile
    else 
        echo "Sample $sample has no final neoantigen result processed by pVACseq, please check it."
    fi
done

# merge all neoantigen files
allfiles=$(ls $final_dir | grep "final")
i=0

for onefile in $allfiles
do
    let i+=1
    
    printf "\rprocess %s .." $onefile
    if [ $i -eq 1 ]; then
        cat $final_dir/$onefile > $neo_dir/"merged_neoantigens.tsv"
    else
        cat $final_dir/$onefile | sed '1d' >> $neo_dir/"merged_neoantigens.tsv"
    fi   
done

if [ $i -eq 0 ]; then
    echo
    echo "Something wrong with files, aborting..."
    exit 1
fi

echo
echo "===> Process of merging Neoantigen files complete successfully!"
echo "$i files have been merged into $neo_dir/merged_neoantigens.tsv."

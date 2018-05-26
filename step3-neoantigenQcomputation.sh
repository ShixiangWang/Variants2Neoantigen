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

###########<<<<<< transform merged file to custom format for neoantigen quality computation
echo "Neoantigens caused by Single Base Substitution will be used to calculate Neoantigen Quality."
Rscript $ShellDIR/r/generate_input_of_NQcomputation.R $neo_dir/merged_neoantigens.tsv $neo_dir "neoantigens.txt"

# get blast results for every neoantigen of every sample
neofa_dir=$neo_dir/neofasta_dir
fafiles=$(ls $neofa_dir | grep "\.fasta$")
#db=~/wangshx/projects/data/iedb/iedb.fasta

source activate $py_env

echo "Run blastp on all neoantigen.fasta files under $neofa_dir ..."
for fafile in $fafiles
do
    xmlfile=$(echo $fafile | sed 's/fasta/xml/')
    printf "\rgenerate %s .." $xmlfile
    blastp -query $neofa_dir/$fafile -db $iedb -outfmt 5 -evalue 100000000 -gapopen 11 -gapextend 1  > $neofa_dir/$xmlfile
done

source deactivate $py_env

# fitness model parameters
a=26.
k=4.86936
#py_dir=~/wangshx/projects/Python/NQcomputation/src
py_dir=$ShellDIR/python          # python script used for calc neoantigen quality

# the modified row
#         xmlpath=alignmentDirectory+"/neoantigens_"+sample+"_iedb.xml"
#change to xmlpath=alignmentDirectory+"/neoantigens_"+sample+".xml"

# Compute Neoantigen Quality
echo
echo "Begin calculating neoantigen quality for all samples..."
#source activate $py_env
python2.7 $py_dir/main.py $neo_dir/neoantigens.txt $neofa_dir $a $k $neo_dir/neoantigen_Quality.txt
#source deactivate $py_env

echo -e "\033[32m Neoantigen Quality Computation finished successfully!!! \033[0m" 

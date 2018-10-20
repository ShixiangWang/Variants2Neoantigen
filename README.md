# Variants2neoanitgen pipeline

To calculate neoantigen from [VCF](https://en.wikipedia.org/wiki/Variant_Call_Format) or [MAF](https://docs.gdc.cancer.gov/Data/File_Formats/MAF_Format/) (MAF-like) file. 

Now pipeline has been implemented and tested is 

* MAF or MAF-like file -> MAF to VCF (by maf2vcf.pl) -> annotated VCF (by VEP) -> single sample neoantigen information (by pvacseq) -> summary neoantigen for all samples (by shell script) -> neoantigen quality (by R script, Shell script and Python script which from paper neoantigen fitness model).

## Concepts

**VCF** and **MAF** files are the most popular text files used in bioinformatics for storing DNA variations. 

[**Tumor antigens**](https://en.wikipedia.org/wiki/Antigen#Tumor_antigens) (also known as *Neoantigens*) are those antigens that are presented by MHC class I or MHC class II molecules on the surface of tumor cells. Antigens found only on such cells are called tumor-specific antigens (TSAs) and generally result from a tumor-specific mutation. For human tumors without a viral etiology, **novel peptides** (neo-epitopes) are created by tumor-specific DNA alterations.

What the pipeline do is provide a quick and easy way to predict neoantigens from variant record files - VCF, MAF or MAF-like files. This pipeline is powered by [VEP](http://asia.ensembl.org/info/docs/tools/vep/script/index.html), [pVACseq](http://pvactools.readthedocs.io/en/latest/pvacseq.html) and [vcf2maf toolkit](https://github.com/mskcc/vcf2maf) etc..

>**Note**, you should have HLA information file of samples when you want to predict neoantigens.

## How it works

[pVACseq](http://pvactools.readthedocs.io/en/latest/pvacseq.html) is a well established tool for predicting tumor-specific mutant peptides (neoantigens). However, it can only accept **VCF** file as input and generate one directory for one samples. This is not convenient to summary the results and expand this tool. Therefore, I build a pipeline to integrate [vcf2maf toolkit](https://github.com/mskcc/vcf2maf) with pVACseq, which translate MAF or MAF-like files to VCF firstly, and then call pVACseq to predict neoantigens and finally summary the data.

**For now, you can use this pipeline to predict neoantigens by MAF file and sample specific HLA information.** VCF to neoantigens and maf-like file to neoantigens are need to be done. **Besides**, after calling neoantigens, you can compute Neoantigen Quality by NetMHC4.0. The method of neoantigen quality computation is published as [*A neoantigen fitness model predicts tumour response to checkpoint blockade immunotherapy*](https://www.nature.com/articles/nature24473).


## Prerequisites

Two main information you must have before you want to predict neoantigens, one is the patient-specific HLAs and the other is detail information of variants, at least have following columns which can be processed by [vcf2maf toolkit](https://github.com/mskcc/vcf2maf).

```
Chromosome  Start_Position  Reference_Allele    Tumor_Seq_Allele2	Tumor_Sample_Barcode
1	3599659	C	T	TCGA-A1-A0SF-01
1	6676836	A	AGC	TCGA-A1-A0SF-01
1	7886690	G	A	TCGA-A1-A0SI-01
```

**Once you have these two information, you can prepare to configure the pipeline now before you use it**.

### Install conda

You can download conda by web brower, Anaconda link is <https://www.anaconda.com/download/> or `curl`, `wget` command tool.

I recommend you install the python2 version conda, it can provide you a python2.7 default environment. Some configuration in our pipeline will use python2.7.

Install conda, run your file use `sh`

for example

```sh
wget -c https://repo.anaconda.com/archive/Anaconda2-5.1.0-Windows-x86_64.exe
sh Anaconda2-5.1.0-Linux-x86_64.sh
```

then follow the commands.

>If you find any problem about installing conda, you can google it, the anaconda is very popular, so many problem you encounter basically have been fixed or discussed.

### Configuration flows

* Clone Variants2neoanitgen pipeline from Github.

```
git clone https://github.com/ShixiangWang/Variants2Neoantigen.git
```


* Install and configure requirements

```sh
# install R and biopython
# these used to calculate neoantigen quality

# if your conda default env is python 2.7, just
conda install -c r r-essentials 
conda install biopython

# if your conda default env is not python2.7, please create a python2.7 env first, then run commands as above
# conda create --name py2 python=2.7

# create a python 3.5 environment, the pvactools need python 3.5
# muliple bioinformatics tools will be installed in this environment too, like blast, samtools etc.
conda create --name pipeline python=3.5
```

```sh
# create an env
source activate pipeline

# install pvactools
pip install pvactools

# install perl and vep
# http://asia.ensembl.org/info/docs/tools/vep/script/vep_download.html#installer
conda install -c conda-forge perl

# configure local-lib, see <https://metacpan.org/pod/local::lib#The-bootstrapping-technique>
wget -c https://cpan.metacpan.org/authors/id/H/HA/HAARG/local-lib-2.000024.tar.gz
tar -zxf local-lib-2.000024.tar.gz 
cd local-lib-2.000024/
perl Makefile.PL --bootstrap=~/perl5 # you can change the ~/perl5 to another location for managing perl modules
make test && make install
echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"' >>~/.bashrc

cpan App::cpanminus
cpanm DBI
cpanm DBD::mysql
# if you encounter error (Ubuntu) like <https://stackoverflow.com/questions/4729722/trying-to-install-perl-mysql-dbd-mysql-config-cant-be-found>, run sudo apt-get install libmysqlclient-dev after sudo apt-get update
cpanm Archive::Extract
cpanm Archive::Zip

# install vep
cd ~
git clone https://github.com/Ensembl/ensembl-vep.git
cd ensembl-vep
perl INSTALL.pl
# select the cache file you want, for example 178 for homo-sapiense GRCh37

export VEP_PATH=$HOME/ensembl-vep
export VEP_DATA=$HOME/.vep

perl INSTALL.pl --AUTO f --SPECIES homo_sapiens --ASSEMBLY GRCh37 --DESTDIR $VEP_PATH --CACHEDIR $VEP_DATA

perl convert_cache.pl --species homo_sapiens --version 92_GRCh37 --dir $VEP_DATA


# add following to you ~/.bashrc
export PERL5LIB=$HOME/ensembl-vep:$PERL5LIB
export PATH=$HOME/ensembl-vep/htslib:$PATH

# cp ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz* to ~/.vep
# You can download from Variants2Neoantigen/data/ dir or generate it following <https://gist.github.com/ckandoth/d135aec7afd8edd73f572584cbf23f5c> (Just content about this is okay)

# test vep
perl vep --species homo_sapiens --assembly GRCh37 --offline --no_progress --no_stats --sift b --ccds --uniprot --hgvs --symbol --numbers --domains --gene_phenotype --canonical --protein --biotype --uniprot --tsl --pubmed --variant_class --shift_hgvs 1 --check_existing --total_length --allele_number --no_escape --xref_refseq --failed 1 --vcf --minimal --flag_pick_allele --pick_order canonical,tsl,biotype,rank,ccds,length --dir $VEP_DATA --fasta $VEP_DATA/homo_sapiens/92_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz --input_file examples/homo_sapiens_GRCh37.vcf --output_file example_GRCh37.vep.vcf --polyphen b --af --af_1kg --regulatory --custom $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz,ExAC,vcf,exact,1,AC,AN

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda/

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
# make sure conda-forge is on the top
# then
conda install -c bioconda samtools bcftools ucsc-liftover blast

# vcf2maf tool
cd ~
export VCF2MAF_URL=`curl -sL https://api.github.com/repos/mskcc/vcf2maf/releases | grep -m1 tarball_url | cut -d\" -f4`
curl -L -o mskcc-vcf2maf.tar.gz $VCF2MAF_URL; tar -zxf mskcc-vcf2maf.tar.gz; mv mskcc-vcf2maf-* vcf2maf
# usage:
# perl vcf2maf.pl --man
# perl maf2maf.pl --man

# test vcf2maf
perl vcf2maf.pl --input-vcf tests/test.vcf --output-maf tests/test.vep.maf --ref-fasta ~/.vep/homo_sapiens/92_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz --vep-path=$HOME/ensembl-vep/

perl maf2maf.pl --input-maf tests/test.maf --output-maf tests/test.vep.maf --ref-fasta ~/.vep/homo_sapiens/92_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa  --vep-path=$HOME/ensembl-vep


# Installing IEDB binding prediction tools (strongly recommended)
# http://pvactools.readthedocs.io/en/latest/install.html#installing-iedb-binding-prediction-tools-strongly-recommended

# make sure tcsh and gawk are installed

```

## Usage

First add path to your `~/.bashrc` and add permission to scripts, so you can run the script from any location.


```sh
./add_path.sh
```

### New Way

From [version 0.2.0](https://github.com/ShixiangWang/Variants2Neoantigen/releases/tag/v0.2.0), new usage is introduced.

Now you can deploy Variants2neoantigen in two steps:

* Preparation - provide input PATH and specify output PATH, generate configure file (inputArgs.txt)
* Run pipeline - run pipeline, the script will use configuration in file under current directory (generated by preparation part)


The corresponding commands are:

1. Preparation


```shell
runNEO_prepare [-i <input_file>] [-o <output_dir>] [--HLA <HLA_file>]
```

This process provide input file including MAF and HLA info and specify output directory path.

2. Run pipeline

```shell
runNEO_run
```

This process start the pipeline, please remember running `runNEO_run` in current directory (the path where your configure file inputArgs.txt are).


You also can use this tool as before.

### Old Way


Modify argument's template file `configureArgs` under `Variants2Neoantigen` directory. Only change the difference between you and this file by following the comments.

```
# This file is used to configure default parameters of neoantigens computation
# If you do not know what it means, DO NOT change it!!!
# If you want help, free to send email to <wangshx@shanghaitech.edu.cn> 

####### <<<<<< Location of Files
##maffiles=$(pwd)/*.maf                       # location of maf file
##OUTPUT=$(pwd)/neoantigen_results
CACHE_VEP=~/.vep/                                           # directory path of ensembl vep cache
PATH_FASTA=~/.vep/homo_sapiens/92_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa           
                                                            # path of reference fasta file
iedb=~/Variants2Neoantigen/data/iedb/iedb.fasta                # iedb database used for blastp
##PATH_HLA=~/wangshx/projects/data/                         # directory path to patient specific HLA alleles file

####### <<<<<< Location of Softwares, python environment and input arguments
py_env=pipeline                                                # python environment, which can run pvacseq (Python 3.5) 
py2_env=py2     # python2.7 

maf2vcf=~/vcf2maf/maf2vcf.pl      # path of maf2vcf.pl script
PATH_VEP=~/ensembl-vep/           # directory path of ensembl vep software
PATH_VEP_PLUGINS=~/VEP_plugins    # directory path of ensembl vep plugins
PATH_MHC=~/MHC                   # directory path of iedb local installation
vep_run=$PATH_VEP/vep

assembly_version="GRCh37"                               # genome build version, must be consistent in the analysis
method="NetMHC"                                         # multiple methods separated by space, like "NetMHC PickPocket NetMHCcons NNalign", but multiple method is not recommend
epitope_len="9"                                         # multiple length separated by comma, like "9,10"

```

Run

```sh
runNEO input.maf output_dir input_HLA.tsv
```

### HLA input

the `input_HLA.tsv` should like

```
Tumor_Sample_Barcode	HLA
sample1	HLA-A*30:01,HLA-B*39:01,HLA-B*38:01,HLA-C*12:03,HLA-A*25:01
sample2	HLA-A*31:01,HLA-B*51:01,HLA-A*68:01,HLA-B*35:08,HLA-C*15:02,HLA-C*04:01
sample3	HLA-A*02:01,HLA-B*44:03,HLA-B*07:02,HLA-A*29:02,HLA-C*16:01,HLA-C*07:02
sample4	HLA-B*15:01,HLA-A*02:01,HLA-B*38:01,HLA-C*03:03,HLA-C*12:03,HLA-A*23:01
sample5	HLA-B*44:03,HLA-B*40:01,HLA-C*03:04,HLA-A*24:02,HLA-A*23:01,HLA-C*02:02
sample6	HLA-A*02:01,HLA-B*13:02,HLA-A*30:01,HLA-C*06:02
sample8	HLA-A*68:01,HLA-B*40:01,HLA-C*04:01,HLA-A*68:02,HLA-B*53:01,HLA-C*03:19
```

two column, the first is the sample id matched with `maf` file, the second is the HLA, they are `tab` separated (tsv file, the header can be none).


All neoantigen results are under `output_dir/neoantigens/`.

## License

GPL3

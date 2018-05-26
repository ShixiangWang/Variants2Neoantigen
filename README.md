# configure for maf2neoanitgen pipeline


### Install conda

You can download conda by web brower, Anaconda link is <https://www.anaconda.com/download/> or `curl`, `wget` command tool.

Install conda, run your file use `sh`

for example

```sh
sh Anaconda3-5.1.0-Linux-x86_64.sh
```

then follow the commands.

## Configuration

```sh
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

# cp ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz to ~/.vep

# test vep
perl vep --species homo_sapiens --assembly GRCh37 --offline --no_progress --no_stats --sift b --ccds --uniprot --hgvs --symbol --numbers --domains --gene_phenotype --canonical --protein --biotype --uniprot --tsl --pubmed --variant_class --shift_hgvs 1 --check_existing --total_length --allele_number --no_escape --xref_refseq --failed 1 --vcf --minimal --flag_pick_allele --pick_order canonical,tsl,biotype,rank,ccds,length --dir $VEP_DATA --fasta $VEP_DATA/homo_sapiens/92_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz --input_file examples/homo_sapiens_GRCh37.vcf --output_file example_GRCh37.vep.vcf --polyphen b --af --af_1kg --regulatory --custom $VEP_DATA/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz,ExAC,vcf,exact,1,AC,AN

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda/

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/

conda install -c bioconda samtools bcftools ucsc-liftover

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
# ID	MUTATION_ID	Sample	WT.Peptide	MT.Peptide	MT.Allele	WT.Score	MT.Score	HLA	chop_score
# 1	1_44084332_G_T_AL4602	AL4602	RGTETCGLI	RVTETCGLI	C1502	1208	124	"A0301,A3201,B0801,B5101,C0702,C1502"	1

Args <- commandArgs(trailingOnly = TRUE)
in_path  <- Args[1]
out_path <- Args[2]
flname   <- Args[3]
merged_neoantigens <- read.delim(file=in_path, stringsAsFactors = FALSE)

# only use SNP (single base substitution)
merged_neoantigens <- subset(merged_neoantigens,
                             nchar(Reference)==1 & nchar(Variant)==1)

Sample     <- merged_neoantigens$Sample.Name
WT.Peptide <- merged_neoantigens$WT.Epitope.Seq
MT.Peptide <- merged_neoantigens$MT.Epitope.Seq
MT.Allele  <- merged_neoantigens$Gene.Name
WT.Score   <- merged_neoantigens$Corresponding.WT.Score
MT.Score   <- merged_neoantigens$Best.MT.Score
HLA        <- merged_neoantigens$HLA.Allele # this is not equal to HLA in paper code
MUTATION_ID<- paste(sub("chr(.*)","\\1",merged_neoantigens$Chromosome),
                    merged_neoantigens$Stop,merged_neoantigens$Reference,
                    merged_neoantigens$Variant,Sample, sep="_")
custom_df <- data.frame(ID=1:length(Sample),
                        MUTATION_ID=MUTATION_ID,
                        Sample=Sample,
                        WT.Peptide=WT.Peptide,
                        MT.Peptide=MT.Peptide,
                        MT.Allele=MT.Allele,
                        WT.Score=WT.Score,
                        MT.Score=MT.Score,
                        HLA=HLA,
                        chop_score=1, stringsAsFactors = FALSE)



gen_neofiles <- function(x, out_path){
    # creat output path
    sink(file = paste0(out_path, "/neoantigens_", as.character(x), ".fasta"))
    sample_df <- subset(custom_df, Sample == as.character(x))
    apply(sample_df, 1, function(y){
        cat(">",as.character(x),"|WT|",
            sub("(\\s)*", "", as.character(y[1])),
            "|",y[2],"\n", sep = "")
        cat(y[4],"\n", sep = "")
        cat(">",as.character(x),"|MUT|",
            sub("(\\s)*", "", as.character(y[1])),
            "|",y[2],"\n", sep = "")
        cat(y[5],"\n", sep = "")
    })
    sink()
}

neofile_dir <- paste(out_path, "neofasta_dir", sep="/")
dir.create(neofile_dir)

for(i in names(table(Sample))){
    cat("Processing", i, "...\n")
    gen_neofiles(x = i, out_path = neofile_dir)
}

cat("==>\n")
cat("All fasta files have been successfully created!!!\n")
cat("Next, we are going to compute Neoantigen Quality...\n")

#write.table(merged_neoantigens, file=paste(out_path,"merged_neoantigens_SNV.tsv",sep="/"), quote=FALSE, row.names=FALSE, col.names=TRUE, fileEncoding="UTF-8", sep="\t")
write.table(custom_df, file=paste(out_path,flname,sep="/"), quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE)


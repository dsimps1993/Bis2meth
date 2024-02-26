#!/bin/bash

#SBATCH --job-name=Bis_toMeth
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --mem=128GB
#SBATCH --partition=batch
#SBATCH --account=vsebast
#SBATCH --time=24:00:00



module load dnmtools/1.2.2
module load bowtie2/2.5.0
module load samtools/1.9
module load ucsc_tools/309





workdir="/labs/vsebast/DJS/Project_Cell_Exh_Ours/d59_reseq"
#remember this is ensembl primary ver here
Index="/labs/vsebast/DJS/genomes/HomoSap/Primary_ver/Homo_sapiens.GRCh38.dna.primary_assembly.fa"


fileID="d59_HA38_reseq"

cd $workdir

#For whatever damn reason I cant get this to run completely locally. Its the count script, I always get the killed 9 thing.

#moving to scg and running there


threads="60"



mkdir ${workdir}/DNMTools_BAMs

#Converting bismark bam file to dnmtools format
dnmtools format -v -bam -f -t $threads bismark Dedup/${fileID}*.bam ${workdir}/DNMTools_BAMs/${fileID}_methForm.bam

mkdir ${workdir}/sortedBams


echo '************************************'
echo Start ${fileID} Sorting:
echo '************************************'
date

#Sorting Sam files
samtools sort -O bam -@ 16  -o ${workdir}/sortedBams/${fileID}_input-sorted.bam ${workdir}/DNMTools_BAMs/${fileID}_methForm.bam


mkdir ${workdir}/uniqueSams


echo '************************************'
echo Start ${fileID} Uniqing:
echo '************************************'
date

#No need since already deduped

#Uniqing
#dnmtools uniq -v sortedSams/${fileID}_input-sorted.sam uniqueSams/${fileID}_out-sorted.sam

#Calculate conversion rate, will comment out now to save time
#dnmtools bsrate [OPTIONS] -c <chroms> <input.sam>

echo '************************************'
echo Start ${fileID} methcounts:
echo '************************************'
date

mkdir ${workdir}/methcounts

#Calculating counts. Doing CpG Context only to save time
dnmtools counts -v -cpg-only -c $Index  -t $threads -o ${workdir}/methcounts/${fileID}.meth ${workdir}/sortedBams/${fileID}_input-sorted.bam


echo '************************************'
echo Start ${fileID} Sym:
echo '************************************'
date

mkdir ${workdir}/symCpGs

#Output to symmetryic CpGs
dnmtools sym -o ${workdir}/symCpGs/${fileID}_sym.meth ${workdir}/methcounts/${fileID}.meth


echo '************************************'
echo Start ${fileID} Bigwigs:
echo '************************************'
date

mkdir $workdir/meth_bigwigs


awk -v OFS="\t" '{print $1, $2, $2+1, $4":"$6, $5, $3}'  $workdir/symCpGs/${fileID}_sym.meth >  $workdir/symCpGs/${fileID}_symmeth.bed

cut -f 1-3,5 $workdir/symCpGs/${fileID}_symmeth.bed | wigToBigWig /dev/stdin /labs/vsebast/DJS/genomes/HomoSap/Primary_ver/hg38_ensembEd.chrom.sizes.txt $workdir/meth_bigwigs/${fileID}_meth.bw


echo '************************************'
echo Start ${fileID} LMRs:
echo '************************************'
date

mkdir $workdir/LMRs

#Finding HMRs/LMRs
dnmtools hmr -v -o $workdir/LMRs/${fileID}.hmr $workdir/symCpGs/${fileID}_sym.meth



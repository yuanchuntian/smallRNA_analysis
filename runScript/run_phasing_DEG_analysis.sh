#!/bin/bash


################
# Major Config #
################
# pipeline version
export smallRNA_downstream_analysis=1.0.0
# this pipeline is still in debug mode
export DEBUG=1 
# pipeline address: if you copy all the files to another directory, this is the place to change; under this directory sits two directories, bin and common. bin stores all the binary executables and common stores all the information of each ORGANISM.
export PIPELINE_DIRECTORY=/home/wangw1/git/smallRNA_analysis
# set PATH to be aware of pipeline/bin; this bin directory needs to be searched first
export PATH=${PIPELINE_DIRECTORY}/:$PATH


INDIR=/home/wangw1/isilon_temp/degradome/ #this is the folder store all pipeline results outmost folders
OUT=/home/wangw1/isilon_temp/smRNA/transposon_piRNA
LOG=${OUT}/log

STEP=1

echo -e "`date` "+$ISO_8601"\tDraw phasing analysis..." >> $LOG
OUTDIR1=${OUT}/degphasing
[ ! -d $OUTDIR1 ] && mkdir -p ${OUTDIR1}
if [ ! -f ${OUT}/.status.${STEP}.transposon_DEG.phasing ] 
then
	#for i in `ls ${INDIR}/*.inserts/*DEG*.norm.bed.gz`
	for i in `find /home/wangw1/isilon_temp/smRNA/pp8_smRNAtrn_vs_degradometrnoutcluster_total_01202014/ -name "*.PE.*norm.bed.gz" |grep IN_CLUSTER`
	do
		inputfile=${i##*/}
		samplenamepart=${inputfile#Phil.DEG.*}
		samplename=${samplenamepart%*.mapper2.norm.bed.gz}
		sample=${samplename/ovary.PE.xkxh./}
		/home/wangw1/bin/submitsge 8 ${sample} $OUTDIR1 "${PIPELINE_DIRECTORY}/run_distance_analysis.sh -i ${i} -o $OUTDIR1 -t normbed -r DEG" 
	done
fi
[ $? == 0 ] && \
touch ${OUT}/.status.${STEP}.transposon_DEG.phasing
STEP=$((STEP+1))

echo -e "`date` "+$ISO_8601"\tgenerate phasing master table..." >> $LOG
#

OUTDIR2=${OUT}/degphasingMaster
[ ! -d $OUTDIR2 ] && mkdir -p ${OUTDIR2}
touch ${OUT}/.status.${STEP}.transposon_DEG.phasing.mastertable
if [ ! -f ${OUT}/.status.${STEP}.transposon_DEG.phasing.mastertable ] 
then
	[ -s ${OUTDIR2}/allpiRNAs.allgt.5-5.distance.min.distribution.summary.raw.txt ] && rm ${OUTDIR2}/allpiRNAs.allgt.5-5.distance.min.distribution.summary.raw.txt
	for i in `ls ${OUTDIR1}/*.ovary.inserts.xkxh.norm.bed.gz.5-5.distance.distribution.summary`
	do
		inputfile=${i##*/}
		insertsname=`basename $inputfile .ovary.inserts.xkxh.norm.bed.gz.5-5.distance.distribution.summary`
		samplename=${insertsname#*.SRA.*}
		
	awk -v gt=${samplename} '{OFS="\t"}{print gt,$1,$2}' ${i} >>${OUTDIR2}/allpiRNAs.allgt.5-5.distance.min.distribution.summary.raw.txt
		
		
	done
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${OUTDIR2}/allpiRNAs.allgt.5-5.distance.min.distribution.summary.raw.txt ${OUTDIR2}/allpiRNAs.allgt.5-5.distance.min.distribution.summary.mastertable.txt 
fi
[ $? == 0 ] && \
touch ${OUT}/.status.${STEP}.transposon_DEG.phasing.mastertable
STEP=$((STEP+1))


STEP=$((STEP+1))

#echo -e "`date` "+$ISO_8601"\tDraw seqlogo of +1U anchoring the 3end ..." >> $LOG
#/home/hanb/scratch/cd/smallRNA_pipeline_output/Phil.SRA.ago3MutsAubMuts.ox.ovary/intersect_piRNA_length/*.insert
#/home/hanb/scratch/cd/smallRNA_pipeline_output/Phil.SRA.w1.ox.ovary/intersect_piRNA_length/*.insert
#seqlogo_ww $i 
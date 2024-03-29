#!/bin/bash -x
export PIPELINE_DIRECTORY=/home/wangw1/git/smallRNA_analysis
script=${PIPELINE_DIRECTORY}/pp8_ww_smRNA_vs_DEG.pl
smRNAINDIR=/home/hanb/scratch/cd/smallRNA_pipeline_output/
degraINDIR=/home/wangw1/isilon_temp/degradome/pipeline_output_12262013
OUT0=/home/wangw1/isilon_temp/smRNA/pp8_smRNAtrninout_vs_degradometrnoutcluster_total_01292014
declare -a FEATURE=("FLY_TRN_ALL" "FLY_TRN_ALL_IN_CLUSTER" "FLY_TRN_ALL_OUT_CLUSTER")
#g=$5
#c=$6 #cpu
declare -a GROUPGT=("ago3MutsWW" "aubvasAgo3CDrescue" "aubvasAgo3WTrescue" "aubMutsWW" "AubCDrescue" "AubWTrescue")
#declare -a GROUPGT=("ago3MutsWW")

STEP=1

[ ! -d ${OUT0} ] && mkdir -p ${OUT0}
#step 1
#OUT=${OUT0}
#touch ${OUT0}/.status.${STEP}.SRA_DEG.pp8
if [ ! -f ${OUT0}/.status.${STEP}.SRA_DEG.pp8 ] 
then
for g in "${GROUPGT[@]}"
do
	for f in "${FEATURE[@]}"
	do
		OUTDIR=${OUT0}/${g}_${f}
		[ ! -d ${OUTDIR} ] && mkdir -p ${OUTDIR}
		
		LOG=${OUTDIR}/${g}.log	
		smmapper2=${OUT0}/Phil.SRA.${g}.ox.ovary.inserts.xkxh.transposon.mapper2.23-29.gz #share the SRA norm.bed files
		demapper2=${OUTDIR}/Phil.DEG.${g}.unox.ovary.PE.xkxh.${f}.mapper2.gz
		[ ! -f $demapper2 ] && \
			ln -s ${degraINDIR}/Phil.DEG.${g}.ovary.PE/bedIntersectWW/Phil.DEG.${g}.ovary.PE.x_rRNA.dm3.sorted.f0x40.noS.5p.all.bed.ntm.collapse.${f}.nta.mapper2.gz $demapper2
		[ ! -f $smmapper2 ] && \
			ln -s ${smRNAINDIR}/Phil.SRA.${g}.ox.ovary.inserts/Phil.SRA.${g}.ox.ovary.inserts.xkxh.transposon.mapper2.23-29.gz ${smmapper2}	
		echo -e "`date` "+$ISO_8601"\tChanged the name of degradome transposon mapper2..." >> $LOG
			
	#length range: 23-29
	#[ ! -f ${smmapper2%.gz}.23-29.gz ] && \
	#${PIPELINE_DIRECTORY}/gzlenrangeselector.pl ${smmapper2} 23 29 >${smmapper2%.gz}.23-29 && \
	#gzip ${smmapper2%.gz}.23-29
		
	#convert mapper2 to norm.bed for pp8
		[ ! -s ${smmapper2%.gz}.norm.bed.gz ] && ${PIPELINE_DIRECTORY}/mapper2gznormbed.pl ${smmapper2} ${OUT0} && gzip ${smmapper2%.gz}.norm.bed
		[ ! -s ${demapper2%.gz}.norm.bed.gz ] && ${PIPELINE_DIRECTORY}/mapper2gznormbed.pl ${demapper2} ${OUTDIR} && gzip ${demapper2%.gz}.norm.bed
		
		echo -e "`date` "+$ISO_8601"\t convert the mapper2 format to norm.bed format done..." >> $LOG
		
		echo -e "`date` "+$ISO_8601"\tSize select the smallRNA transposon mapper2 and gzip it..." >> $LOG
	#total Ping-Pong
		[ ! -s ${OUT0}/${g}_${f}.total.pp8.out ] && submitsge 8 ${g}_${f} ${OUT0} "$script ${smmapper2%.gz}.norm.bed.gz ${demapper2%.gz}.norm.bed.gz 2 ${OUTDIR} >${OUT0}/${g}_${f}.total.pp8.out" 
		echo -e "`date` "+$ISO_8601"\ttotal Ping-Pong 8 analysis done..." >> $LOG
	done
done
fi
[ $? == 0 ] && \
touch ${OUT0}/.status.${STEP}.SRA_DEG.pp8
STEP=$((STEP+1))


#generate master table for ppscore
masterOUT=${OUT0}/masterpp8score
[ ! -d ${masterOUT} ] && mkdir -p ${masterOUT}
if [ ! -f ${OUT0}/.status.${STEP}.SRA_DEG.pp8.master ] 
then
	for f in "${FEATURE[@]}"
	do
		[ -f ${masterOUT}/SRA_transposon.SRA_transposon_${f}.nonnormalized.pp8score.txt ] && rm ${masterOUT}/SRA_transposon.SRA_transposon_${f}.nonnormalized.pp8score.txt
		[ -f ${masterOUT}/SRA_transposon.DEG_${f}.nonnormalized.pp8score.txt ] && rm ${masterOUT}/SRA_transposon.DEG_${f}.nonnormalized.pp8score.txt
		[ -f ${masterOUT}/DEG_${f}.SRA_transposon.nonnormalized.pp8score.txt ] && rm ${masterOUT}/DEG_${f}.SRA_transposon.nonnormalized.pp8score.txt
		[ -f ${masterOUT}/DEG_${f}.DEG_${f}.nonnormalized.pp8score.txt ] && rm ${masterOUT}/DEG_${f}.DEG_${f}.nonnormalized.pp8score.txt
		
		[ -f ${masterOUT}/SRA_transposon.SRA_transposon_${f}.normalized.pp8score.txt ] && rm ${masterOUT}/SRA_transposon.SRA_transposon_${f}.normalized.pp8score.txt
		[ -f ${masterOUT}/SRA_transposon.DEG_${f}.normalized.pp8score.txt ] && rm ${masterOUT}/SRA_transposon.DEG_${f}.normalized.pp8score.txt
		[ -f ${masterOUT}/DEG_${f}.SRA_transposon.normalized.pp8score.txt ] && rm ${masterOUT}/DEG_${f}.SRA_transposon.normalized.pp8score.txt
		[ -f ${masterOUT}/DEG_${f}.DEG_${f}.normalized.pp8score.txt ] && rm ${masterOUT}/DEG_${f}.DEG_${f}.normalized.pp8score.txt
		for g in "${GROUPGT[@]}"
		do
			OUTDIR=${OUT0}/${g}_${f}
			cut -f1,2 ${OUTDIR}/${g}_SRA_transposon.${g}_SRA_transposon.pp|awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}' >> ${masterOUT}/SRA_transposon.SRA_transposon_${f}.nonnormalized.pp8score.txt
			cut -f1,2 ${OUTDIR}/${g}_SRA_transposon.${g}_DEG_${f}.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/SRA_transposon.DEG_${f}.nonnormalized.pp8score.txt
			cut -f1,2 ${OUTDIR}/${g}_DEG_${f}.${g}_SRA_transposon.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/DEG_${f}.SRA_transposon.nonnormalized.pp8score.txt
			cut -f1,2 ${OUTDIR}/${g}_DEG_${f}.${g}_DEG_${f}.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/DEG_${f}.DEG_${f}.nonnormalized.pp8score.txt
	
			cut -f1,3 ${OUTDIR}/${g}_SRA_transposon.${g}_SRA_transposon.pp|awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}' >> ${masterOUT}/SRA_transposon.SRA_transposon_${f}.normalized.pp8score.txt
			cut -f1,3 ${OUTDIR}/${g}_SRA_transposon.${g}_DEG_${f}.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/SRA_transposon.DEG_${f}.normalized.pp8score.txt
			cut -f1,3 ${OUTDIR}/${g}_DEG_${f}.${g}_SRA_transposon.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/DEG_${f}.SRA_transposon.normalized.pp8score.txt
			cut -f1,3 ${OUTDIR}/${g}_DEG_${f}.${g}_DEG_${f}.pp |awk -v gt=$g 'BEGIN{OFS="\t"}{print gt,$1,$2}'>> ${masterOUT}/DEG_${f}.DEG_${f}.normalized.pp8score.txt
	
		done
		
	
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/SRA_transposon.SRA_transposon_${f}.nonnormalized.pp8score.txt ${masterOUT}/SRA_transposon.SRA_transposon_${f}.nonnormalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/SRA_transposon.DEG_${f}.nonnormalized.pp8score.txt ${masterOUT}/SRA_transposon.DEG_${f}.nonnormalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/DEG_${f}.SRA_transposon.nonnormalized.pp8score.txt ${masterOUT}/DEG_${f}.SRA_transposon.nonnormalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/DEG_${f}.DEG_${f}.nonnormalized.pp8score.txt ${masterOUT}/DEG_${f}.DEG_${f}.nonnormalized.pp8score.mastertable.txt
		
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/SRA_transposon.SRA_transposon_${f}.normalized.pp8score.txt ${masterOUT}/SRA_transposon.SRA_transposon_${f}.normalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/SRA_transposon.DEG_${f}.normalized.pp8score.txt ${masterOUT}/SRA_transposon.DEG_${f}.normalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/DEG_${f}.SRA_transposon.normalized.pp8score.txt ${masterOUT}/DEG_${f}.SRA_transposon.normalized.pp8score.mastertable.txt
	${PIPELINE_DIRECTORY}/RRR ${PIPELINE_DIRECTORY}/R.source cast_master_table ${masterOUT}/DEG_${f}.DEG_${f}.normalized.pp8score.txt ${masterOUT}/DEG_${f}.DEG_${f}.normalized.pp8score.mastertable.txt
	done
fi

[ $? == 0 ] && \
	touch ${OUT0}/.status.${STEP}.SRA_DEG.pp8.master
STEP=$((STEP+1))
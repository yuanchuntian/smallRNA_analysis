#!/bin/sh

#11/05/2013
#WEI WANG
#for Ping-Pong method paper, analyze the data from Yuki lab


indexFlag=$1

STEP=1
#run pp6 for total
touch .status.${STEP}.pp6forTotal
[ ! -f .status.${STEP}.pp6forTotal ] && \
totalBED=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.TOTAL.DMSO.ox.BmN4cell.inserts/Yuki.SRA.TOTAL.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.bed2 && \
submitsge 24 TOTALBEDPP6 ~/isilon_temp/BmN4/pp6_TOTAL "awk '{OFS=\"\\t\"}{print \$1,\$2,\$3,\$4,\$4/\$5,\$6}' ${totalBED} >${totalBED%.bed2}.normalized.bed && /home/wangw1/git/smallRNA_analysis/pp6_ww_bed.pl -i ${totalBED%.bed2}.normalized.bed -o ~/isilon_temp/BmN4/Yuki.SRA.TOTAL.DMSO.ox.BmN4cell.inserts/pp6_total -f bedscore " && \
touch .status.${STEP}.pp6forTotal
STEP=$((STEP+1))

#run pp6 between Ago3 and Siwi
AGO3BED=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.bed2 
SIWIBED=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.bed2
touch .status.${STEP}.pp6forAgo3andSiwi
[ ! -f .status.${STEP}.pp6forAgo3andSiwi ] && \
submitsge 24 AGO3SIWIPP6 ~/isilon_temp/BmN4/pp6_TOTAL "awk '{OFS=\"\\t\"}{print \$1,\$2,\$3,\$4,\$4/\$5,\$6}' ${AGO3BED} >${AGO3BED%.bed2}.normalized.bed && awk '{OFS=\"\\t\"}{print \$1,\$2,\$3,\$4,\$4/\$5,\$6}' ${SIWIBED} >${SIWIBED%.bed2}.normalized.bed && \
/home/wangw1/git/smallRNA_analysis/pp6_ww_bed.pl -i ${AGO3BED%.bed2}.normalized.bed -j ${SIWIBED%.bed2}.normalized.bed -o ~/isilon_temp/BmN4/pp6_TOTAL -f bedscore" && \
touch .status.${STEP}.pp6forAgo3andSiwi
STEP=$((STEP+1))


#converting to mapper2 to norm.bed format,by mapper2normbed.pl
# run pp8_q2_ww1_zscore_sep_11052013.pl for UA_VA
declare -a GT=("Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell" "Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell" "Yuki.SRA.TOTAL.DMSO.ox.BmN4cell")
declare -a TARGETS=("GENE" "KNOWNTE" "ReASTE")
OUTDIR=/home/wangw1/isilon_temp/BmN4/pp8_q2
[ ! -f .status.${STEP}.pp8_UA_VA ] && \
for t in ${TARGETS[@]}
do
	fasta=/home/wangw1/pipeline_bm/common/silkgenome.fa
	A=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.${t}.AS.norm.bed.gz
	B=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.${t}.S.norm.bed.gz
	jobname=${t}_Ago3AS_SiwiS.pp8.q2
	OUT=${OUTDIR}/${t}_Ago3AS_SiwiS
	[ ! -d ${OUT} ] && mkdir -p ${OUT}
	/home/wangw1/bin/submitsge 24 ${jobname} $OUTDIR "/home/wangw1/git/smallRNA_analysis/Ping_Pong/pp8_q2_ww1_zscore_sep_11052013.pl ${A} ${B} 2 $fasta ${OUT} ${indexFlag}>${OUTDIR}/${t}_Ago3AS_SiwiS.pp8.q2.UA_VA.log"

	A=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGBmAgo3IP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.${t}.S.norm.bed.gz
	B=/home/wangw1/isilon_temp/BmN4/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.inserts/Yuki.SRA.FLAGSiwiIP.DMSO.ox.BmN4cell.bmv2v0.all.all.xrRNA.xtRNA.xh.${t}.AS.norm.bed.gz
	jobname=${t}_Ago3S_SiwiAS.pp8.q2
	OUT=${OUTDIR}/${t}_Ago3S_SiwiAS
	[ ! -d ${OUT} ] && mkdir -p ${OUT}
	/home/wangw1/bin/submitsge 24 ${jobname} $OUTDIR "/home/wangw1/git/smallRNA_analysis/Ping_Pong/pp8_q2_ww1_zscore_sep_11052013.pl ${A} ${B} 2 $fasta ${OUT} ${indexFlag} >${OUTDIR}/${t}_Ago3S_SiwiAS.pp8.q2.UA_VA.log"	
done
[ $? == 0 ] && \
touch .status.${STEP}.pp8_UA_VA


#zip the mapper2 format, run pp6
#Ago3IP S: SiwiIP AS, Ago3IP AS: SiwiIP S, Ago3IP total: SiwiIP total	
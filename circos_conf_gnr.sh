#!/bin/bash


OUTDIR=/home/wangw1/src/circos-0.56/fly/etc
STATFILE=CIRCOSBIN.${RANDOM}.stat
for file in "$@"
do
CIRCOSBIN=$file
filename=${CIRCOSBIN##*/}
awk -v f=filename '{BEGIN{OFS="\t"}if(min==""){min=max=$4}; if($4>max) {max=$4}; if($4< min) {min=$4}; total+=$4; count+=1} END {print f,total/count, min, max}' $CIRCOSBIN >>${OUTDIR}/${STATFILE}
done
maxvalue=`awk '{BEGIN{OFS="\t"}if(min==""){min=max=$4}; if($4>max) {max=$4}; if($4< min) {min=$4};END {print max}' ${STATFILE}`

echo "
#karyotype = ../data/karyotype.drosophila.hires.dm3.txt
karyotype = ../data/karyotype.fly.all.dm3.txt
chromosomes_units           = 1000000
chromosomes_display_default = yes
#chromosomes_scale = chrx:2
#chromosomes_order = chrx,chr2l,chr3l,chr2r,chr3r,chr4
#relative order
#chromosomes_order = chr1,chr4,‐,chr3,chr5
#chromosomes = chrx:8-12;chr2l:4-11;chr3R:9-21
#chromosomes_breaks = -chr2l:11-19
	<plots>
" >>file.conf
num_vars=$#
count=0
radius_inc=$((0.6/${num_vars}))
base=0.55
for CIRCOSBIN in "$@"
do
filename=${CIRCOSBIN##*/}
if [[ $filename =~ "plus" ]]
then
rr0=$(($base+$count*$radius_inc))
echo "

	<plot>
	type  = line
	min   = 0
	max   = $maxvalue
	file  = ${CIRCOSBIN}
	r0    = 0.4r
	r1    = 0.6r
	color = vvdblue
	thickness = 0.75
	</plot> " >>file.conf
fi

if [[ $filename =~ "minus" ]]
then 
echo "
	<plot>
	type  = line
	min   = 0
	max   = $maxvalue
	file  = ${CIRCOSBIN}
	r0    = 0.5r
	r1    = 0.80r
	color = vvdred
	thickness = 0.75
	</plot> " >>file.conf
fi
count=$(($count+1))
done

echo "
	</plots>
<<include ideogram.conf>>
<<include ticks.conf>>

<image>
<<include ../../etc/image.conf>>
</image>

<<include ../../etc/housekeeping.conf>>
" >file.conf
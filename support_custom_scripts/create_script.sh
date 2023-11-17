#!/usr/bin/env bash

READS_DIR=$1
WORKDIR=$(pwd)
FINAL_LST=${WORKDIR}'/import.csv'


echo "sample-id,absolute-filepath,direction" > ${FINAL_LST}

for READ1 in $(ls ${READS_DIR}/*_R1*); do
	READ2=`echo ${READ1} | sed -r 's/\_R1/\_R2/'`
	
	### since READ1 had the path, so will READ2 have the path which the sample name should have so we need to remove it
	NAME=`echo ${READ1} | sed -r 's/\_R1.*//; s,.*\/,,'`
	### alternativelly you can use basename after the 1st sed: NAME=`echo ${READ1} | sed -r 's/\_R1.*//'`; NAME=`basename $NAME`
	
	echo -en "${NAME},${READ1},forward\n${NAME},${READ2},reverse\n" >> ${FINAL_LST}
	### in echo '-e' enables usage of special symbols like \t for tabulation or \n for enter
	### '-n' removes enter from the end of the line (thus you have to provide it yourself) - in this code it can be avoided and then so should be the '\n' at the end of the printed line
done

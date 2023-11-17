#!/bin/bash


### reading the path to the file (with the file name)
FILE_LOC=`realpath $1`


############
# DEFAULTS
############
### checking if the location for file was provided, the file exists or is non-zero size
if [[ `echo ${FILE_LOC} | grep -E "^$"`  || ! -e ${FILE_LOC} || -z ${FILE_LOC} ]]; then
  echo -en "\n***[ERROR] You need to provide the location and file name for mapfile.tsv\n\n"; exit 2; fi;


unset TOP_LN COL_LN CAT_COL NUM_COL
declare -a TOP_LN=(`head -n 1 ${FILE_LOC}`)
declare -a COL_LN=(`head -n 22 ${FILE_LOC} | tail -n 1`)
declare -a CAT_COL
declare -a NUM_COL
declare -a UNC_COL

### number of columns
#NCOL=${#COL_LN[@]}

### index start from 1 not 0 as this is the sampleID column
idx=1
RE1='[a-zA-Z]+'
RE2='[0-9]+[.]?[0-9]*$'
while [[ ${idx} -le ${#COL_LN[@]} ]]; do
    if [[ ${COL_LN[$idx]} =~ ${RE2} ]] && ! [[ ${COL_LN[$idx]} =~ ${RE1} ]]; then NUM_COL=(${NUM_COL[@]} ${TOP_LN[$idx]});
  elif [[ ${COL_LN[$idx]} =~ ${RE1} ]]; then CAT_COL=(${CAT_COL[@]} ${TOP_LN[$idx]});
  else UNC_COL=(${UNC_COL[@]} ${TOP_LN[$idx]}); fi
  ((idx++))
done


echo "Numeric columns: ${NUM_COL[@]}"
echo "Categoric columns: ${CAT_COL[@]}"
echo "Unidentified columns: ${UNC_COL[@]}"

#!/usr/bin/env Rscript

rm(list=ls())

### "Script for trimming sequences at 5' and 3' ends for qiime2 dada2 step"
### 19.07.2023

### syntax:
### Rscript seq_trim.R name_of_the_file.tsv  /path/to/table/file/ 50


#options(echo=TRUE)                        ### if you want see commands in output file
### args[1] => path to data information files (default: current directory)
### args[2] => input file from data.qzv
### args[3] => percentile at which consider trimming (default: 50% => median)
args <- commandArgs(trailingOnly = TRUE)

INFILE  <- args[1]
WORKDIR <- args[2]
PERCENT <- args[3]

################
### DEFAULTS ###
################

DEF_WORKDIR <- getwd()
DEF_PERCENT <- 50
ALLOWED_PERCENT <- c(2,9,25,50,75,91,98)

###########################
### CHECKING VARIABLES ###
#########################

if(length(args) == 0) { stop(paste('Need to provide at least one parameter: Input File'),call.=F ) }

if (!exists("WORKDIR",envir=.GlobalEnv, mode="character") || is.na(WORKDIR)) { WORKDIR <- DEF_WORKDIR }
if (!dir.exists(WORKDIR)) { stop(paste('Directory: ',WORKDIR,' does not exist!'),call.=F ) }

if (!file.exists(paste0(WORKDIR,"/",INFILE))) { stop(paste('Input file: ',INFILE,' does not exist!'),call.=T ) } else {
  TABLE <- read.table(paste0(WORKDIR,"/",INFILE),sep ="\t", header = TRUE) }

if (!exists("PERCENT",envir=.GlobalEnv, mode="integer")) { PERCENT <- DEF_PERCENT }
if (!any(ALLOWED_PERCENT == PERCENT)) { PERCENT <- DEF_PERCENT }

######################
### CLEANING TABLE ###
######################

rownames(TABLE) <- c('count',ALLOWED_PERCENT)
TABLE <- TABLE[-1]
colnames(TABLE) <- 1:ncol(TABLE)
TABLE.SLICE <- TABLE[rownames(TABLE) == PERCENT, ]

### 5' - end
s1 <- 1;
t5p <- NULL
MIDDLE <- ncol(TABLE.SLICE)/2

while (s1 < MIDDLE) {
 e1 <- s1 +4
 s2 <- e1 +1; e2 <- s2 +4
 s3 <- e2 +1; e3 <- s3 +4

 MD1 <- median(unlist(TABLE.SLICE[s1:e1]))
 MD2 <- median(unlist(TABLE.SLICE[s2:e2]))
 MD3 <- median(unlist(TABLE.SLICE[s3:e3]))
 #SD1 <- sd(unlist(TABLE.SLICE[s1:e1]))
 SD2 <- sd(unlist(TABLE.SLICE[s2:e2]))
 SD3 <- sd(unlist(TABLE.SLICE[s3:e3]))
 
 if (MD1 >= MD2 - SD2 && MD1 >= MD3 - SD3 && 
     MD1 <= MD2 + SD2 && MD1 <= MD3 + SD3) { t5p <- s1; break }
 s1 <- s1 +1
} 
if (s1 >= MIDDLE || is.null(t5p)) { stop(paste('Could not find 5\' trimming point'), call.=F ) }
rm(SD2,SD3,MD1,MD2,MD3,s1,s2,s3,e1,e2,e3)

### 3' - end
e3 <- ncol(TABLE.SLICE);
#s1 <- MIDDLE +1
t3p <- NULL

while (e3 > MIDDLE) {
  s3 <- e3 -4
  e2 <- s3 -1; s2 <- e2 -4
  e1 <- s2 -1; s1 <- e1 -4
  
  MD1 <- median(unlist(TABLE.SLICE[s1:e1]))
  MD2 <- median(unlist(TABLE.SLICE[s2:e2]))
  MD3 <- median(unlist(TABLE.SLICE[s3:e3]))
  SD1 <- sd(unlist(TABLE.SLICE[s1:e1]))
  SD2 <- sd(unlist(TABLE.SLICE[s2:e2]))
  #SD3 <- sd(unlist(TABLE.SLICE[s3:e3]))
  
  if (MD3 >= MD2 - SD2 && MD3 >= MD1 - SD1 &&
      MD3 <= MD2 + SD2 && MD3 <= MD1 + SD1) { t3p <- e3 -1; break }
  e3 <- e3 -1
} 

if (e3 <= MIDDLE || is.null(t3p)) { stop(paste('Could not find 3\' trimming point'), call.=F ) }
rm(SD2,SD1,MD1,MD2,MD3,s1,s2,s3,e1,e2,e3)

### return values for positions at t5p - 5' and t3p - 3' end
print(c(t5p,t3p))

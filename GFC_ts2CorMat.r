#!/usr/bin/env Rscript

###################################################################
# Script meant to make CPM easier for HCP subs
#
# Assumes a subject has gone through preprocessing and power264 extraction
# generates a bunch of cor matrices of interest for prediction analyses
###################################################################

library(readr)
suppressMessages(require(optparse))
suppressMessages(require(pracma))

root_dir<-"/cifs/hariri-long/Studies/DNS/Imaging/derivatives"

###################################################################
# Parse arguments to script, and ensure that the required arguments
# have been passed.
###################################################################
option_list = list(
  make_option(c("-s", "--subject"), action="store", default=NA, type='character',
              help="4 digit DNS ID, eg 0007")
)
opt = parse_args(OptionParser(option_list=option_list))

if (is.na(opt$subject)) {
  cat('User did not specify a subject ID.\n')
  quit()
}

subject <- opt$subject
dir.create(paste(root_dir,"/GFC/sub-",subject,"/parcellations",sep=""), showWarnings = TRUE, recursive = TRUE, mode = "0777")

################################################################### 
# 1. read the power264 time series inputs
###################################################################
full_mat<-matrix(NA,nrow=0,ncol=0)
for ( task in c("cards","facename","faces","numLS","rest") ) {
	filename=paste(root_dir,"/epiMinProc_",task,"/sub-",subject,"/parcellations/power264.txt",sep="")
	info = file.info(filename)
	if ( file.exists(filename) & info$size != 0 ) {
		mat<-read_delim(filename,delim=" ",col_names = F)
		tmp<-rbind(full_mat,mat)
		full_mat<-tmp
		cat(paste(filename, "included", sep=" "),file=paste(root_dir,"/GFC/sub-",subject,"/parcellations/corMat_power264.log",sep=""),sep="\n",append=TRUE)
	} else {
		cat(paste(filename, "does not exist or is empty!", sep=" "),file=paste(root_dir,"/GFC/sub-",subject,"/parcellations/corMat_power264.log",sep=""),sep="\n",append=TRUE)
		# print(paste(filename, "does not exist or is empty!", sep=" "))
	}
}
corMat<-cor(full_mat)

write.table(as.data.frame(corMat),paste(root_dir,"/GFC/sub-",subject,"/parcellations/corMat_power264.txt",sep=""),quote = F, row.names = F,col.names = F,sep=",")

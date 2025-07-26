# r.data.table code to help grok system logs from Quantum Fiber C6500XK Router
# 7:22 PM 7/25/2025
# CRAN R4.5
# Firmware CKT002-02.04.56.00
# install packages if needed: install.packages(c("data.table","lubridate"))
library(data.table)
library(lubridate)
# set working directory for downloaded System Logs...
setwd("F:/Downloads")

syslog <- fread("systemlog.07.24.2025_001.csv",sep = "|",
	col.names=c("date","time","type","message","lgcl"))
syslog_ <- 
syslog[,.(Date=dmy(date),
	Time=as.ITime(strptime(time,tz="America/Los_Angeles","%r")),
	M=substr(time,9,10),type,message)][order(-Date,-Time)]
syslog_[,c("category","message"):=tstrsplit(message,"::",fixed=TRUE)][]
setDT(syslog_)

# data.table use as DT[i,j,k] See https://github.com/Rdatatable/data.table
# and / or https://cran.r-project.org/web/packages/data.table/vignettes/datatable-intro.html
# Examples:
syslog_[,.N,.(type)][order(-N)]
syslog_[,.N,.(type,category)][order(-N)]
syslog_[type == "Firewall",.N,.(message)]
syslog_[grepl("down",category,ignore.case = TRUE),.N,.(type,category)][order(-N)]
syslog_[grepl("down",category,ignore.case = TRUE),][order(-Date,-Time)]
syslog_[grepl("down",category,ignore.case = TRUE) & category == "Interface Down",][order(-Date,-Time)]
syslog_[grepl("down",category,ignore.case = TRUE) & category == "LCP DOWN",][order(-Date,-Time)]
syslog_[category %in% c("Status Connected","Status Connecting","Interface Down")][order(-Date,-Time)]
syslog_[Date==as.Date(now()),][order(-Date,-Time)] # today
syslog_[Date==as.Date(now()) - 1,][order(-Date,-Time)] # yesterday
syslog_[Date==as.Date(now()) - 2,][order(-Date,-Time)] # two days ago
syslog_[Date==as.Date(now()) - 3,][order(-Date,-Time)] # three days ago

# Firelog parsing
# not really working well yet (3:54 PM 7/25/2025)

syslog_firewall_subset <- syslog_[type == "Firewall",][,c(1:2,5)]
setDT(syslog_firewall_subset)
# Examples
syslog_firewall_subset[grepl("deny",message,ignore.case=TRUE),.N,.(message)]
fwrite(syslog_firewall_subset,"syslog_firewall_subset.txt")
file.show("syslog_firewall_subset.txt")

syslog_firewall <- syslog_[type == "Firewall",]
setDT(syslog_firewall)
# list <- c("name","enable","target","src","dest","dest_port","family","proto","extra","more_extra") 
syslog_firewall[,c("name","enable","target","src","dest","dest_port","family","proto","extra","more_extra")
	:=tstrsplit(message,c(":"),names=TRUE,fill="<NA>",fixed=FALSE)]
setDT(syslog_firewall)[]
# Examples
syslog_firewall[,.N,.(enable,target,src,dest_port,family)][order(-N)]
syslog_firewall[grepl("Allow",enable),.N,.(enable,target,src,dest_port)][order(-N)]
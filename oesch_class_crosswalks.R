# Oesch crosswalk
# Maps ISCO occupation codes onto Oesch' 9 class categories
# Note: technically we want to use other variables to do with employment status in addition to occupation
# See Oesch's code scripts here: http://people.unil.ch/danieloesch/scripts/
# But just using occupation gives a fairly good approximiation

# load packages
library(tidyverse)
library(rio)

# Oesch provides a simple crosswalk but it's in Excel format and a bit messy
# Let's download the .xls files and covert them to .csv

# Save URLs for files from Oesch's website
url_isco_08_4dig <- "http://people.unil.ch/danieloesch/files/2014/05/Final_proposition_passage_ISCO08_Oesch_10_06_2014.xls"
url_isco_08_2dig <- "http://people.unil.ch/danieloesch/files/2014/05/Passage_ISCO08_2DIGIT_Oesch_7Jan2015.xls"
url_isco_88_4dig <- "http://people.unil.ch/danieloesch/files/2014/05/ISCO88_codes_16classes_3April2013.xlsx"
url_isco_88_2dig <- "http://people.unil.ch/danieloesch/files/2014/05/ISCO88_2DIGIT_codes_16classes_7January2015.xlsx"

# Download the spreadsheets
download.file(url_isco_08_4dig, destfile="/Users/sophiehill/Google Drive/Harvard/Populism/Ideas/Data/EB_ESS_combined/oesch_08_4dig.xls")
download.file(url_isco_08_2dig, destfile="/Users/sophiehill/Google Drive/Harvard/Populism/Ideas/Data/EB_ESS_combined/oesch_08_2dig.xls")
download.file(url_isco_88_4dig, destfile="/Users/sophiehill/Google Drive/Harvard/Populism/Ideas/Data/EB_ESS_combined/oesch_88_4dig.xlsx")
download.file(url_isco_88_2dig, destfile="/Users/sophiehill/Google Drive/Harvard/Populism/Ideas/Data/EB_ESS_combined/oesch_88_2dig.xlsx")

# use the "rio" package to convert to .csv format
rio::convert("oesch_08_4dig.xls", "oesch_08_4dig.csv")
rio::convert("oesch_08_2dig.xls", "oesch_08_2dig.csv")
rio::convert("oesch_88_4dig.xlsx", "oesch_88_4dig.csv")
rio::convert("oesch_88_2dig.xlsx", "oesch_88_2dig.csv")

# open the .csv files and clean
oesc_08_4dig <- read.csv("oesch_08_4dig.csv")
oesc_08_4dig <- oesc_08_4dig[,1:3]
oesc_08_4dig[,1] <- as.character(oesc_08_4dig[,1])
oesc_08_4dig[,3] <- as.numeric(as.character(oesc_08_4dig[,3]))
str(oesc_08_4dig)

# save files names in a vector
fileNames <- c("oesch_08_4dig.csv", "oesch_08_2dig.csv", "oesch_88_4dig.csv", "oesch_88_2dig.csv")

# loop over the vector of filenames,
# and for each one:
# read the csv file
# select the first 3 columns (there is some extraneous material in later columns)
# make sure numerics codes are in a safe format
# write a new csv file with the suffix "_cleaned"
for (fileName in fileNames) {
  data <- read.csv(fileName)
  data <- data[,1:3]
  data[,1] <- as.character(data[,1])
  data[,3] <- as.numeric(as.character(data[,3]))
  write.csv(data, file=paste0(substr(fileName, 1, 13), "_cleaned.csv"))
}


## pisa2022
## international dataset: CY08MSP_STU_QQQ.sav
## hk sub dataset: pisa2022hk5907.sav
## Part I: define item, recode value, set correlation type
## Claude-3.7-Sonnet
## LAM Wai Ip
## 23 June 2025

#==========

# Input dataset stored in working directory
# Output dataset saved in pisa_results under working directory 

#==========

# Read the CSV file
input_items <- read.csv("input_items.csv", stringsAsFactors = FALSE)

#==========

# Defining constants

output_dir <- "pisa_results"

# Define the file data and path for pisa2022hk input from SPSS
file_spss_path <- "pisa2022hk5907.sav"      #file name of spss file
file_r_data <- "pisa2022hk"                 #variable name of the R data
file_r_path <- "pisa2022hk.rds"             #file name of the R data
file_csv_data <- "pisa2022hk_transformed"   #variable name for the csv file 

# principal components (fa="pc") or a principal axis factor analysis (fa="fa") 
fa <- "both"

# select items for analysis
item_prefix <- "ST"

#==========

# Run the analysis script while capturing console output
source("pisa2022hk5907_II_multi_analysis_v15.R")

#==========
  
# Re-open device
dev.new()

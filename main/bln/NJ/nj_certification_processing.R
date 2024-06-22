# Import required libraries
library(tidyverse)
library(lubridate)
library(readxl)
library(janitor)

# Clear workspace
rm(list = ls())

# Define root directory and output directory
root_dir = getwd()
output_dir = "data/processed/"

# Define the paths to the raw source Excel file from New Jersey
employment_file = "data/source/nj_response_opra_request.xlsx"

# Define the paths to the output CSV files
nj_index = "data/processed/nj-2023-index.csv"
nj_index_enhanced = "data/processed/nj-2023-index-enhanced.csv"
nj_original_employment = "data/processed/nj-2023-original-employment.csv"

# Create a template dataframe for the officers index.
# This will be used to ensure that the final dataframe has the correct structure.
template_index <- data.frame("person_nbr" = character(0),
                             "full_name" = character(0),
                             "first_name" = character(0),
                             "middle_name" = character(0),
                             "last_name" = character(0),
                             "suffix" = character(0),
                             "year_of_birth" = numeric(0),
                             "age" = numeric(0),
                             "agency" = character(0),
                             "type" = character(0),
                             "rank" = character(0),
                             "start_date" = as.Date(character(0)),
                             "end_date" = as.Date(character(0))
)

# Import the Excel files, converting date columns with hard NULL values to NA. 
nj_history <- read_excel(employment_file, 
                         col_types = c("text", "numeric", "date","text","text","date","text",
                                       "text", "text", "text", "text")) %>% janitor::clean_names()
# name columns for consistency
colnames(nj_history) <- c("full_name","age","date_of_birth","race","gender",
                          "start_date","type","change_reason","agency","agency_type","agency_ori_nbr")

# Create a new column for the year of birth, extracted from date of birth
nj_history$year_of_birth <- year(nj_history$date_of_birth)

# Calculate age of officer in years based on the date of birth; calculated based on day processed
nj_history$age <- as.numeric(difftime(Sys.Date(), nj_history$date_of_birth, units = "days") / 365.25)
nj_history$age <- floor(nj_history$age)

# Remove the date_of_birth column, which we're not releasing in public files but will remain
# available on request for working journalists
nj_history <- nj_history %>% select(-date_of_birth)

# output the original employment data in CSV format
write_csv(nj_history, nj_original_employment)

# If date of birth is 1900-01-01, replace date of birth and age with an NA character
nj_history$age[nj_history$year_of_birth == "1900"] <- NA
nj_history$age[nj_history$year_of_birth == "1900"] <- NA
# If start_date is 1900-01-01, replace with an NA character
nj_history$start_date[nj_history$start_date == as.Date("1900-01-01")] <- NA

# Drop agency type and agency ori number (FBI ID number for agency)
nj_history <- nj_history %>% select(-agency_type, -agency_ori_nbr)
# Drop race and gender for index file; remains in raw CSV file
nj_history <- nj_history %>% select(-race, -gender)

# Extract last name from everything prior to the first comma
nj_history$last_name <- gsub(",.*", "", nj_history$full_name)
# Populate rest_name from everything after the first ", "
nj_history$rest_name <- gsub(".*, ", "", nj_history$full_name)

# Split the name parts for further cleaning and processing
split_names <- strsplit(nj_history$rest_name, " ")
# Assign the corresponding elements from the split name to new columns
nj_history$first_name <- sapply(split_names, '[', 1)
nj_history$middle_name <- sapply(split_names, '[', 2)
nj_history$suffix <- sapply(split_names, '[', 3)

# If suffix is not NA and not equal to "Jr", "Sr", "Jr.","JR.","SR.","II","IV","Sr.", or "V" 
# then append to middle_name column
nj_history$middle_name <- ifelse(!is.na(nj_history$suffix) & !nj_history$suffix %in% c("Jr", "Sr", "Jr.","JR.","SR.","II","IV","Sr.", "V"), paste(nj_history$middle_name, nj_history$suffix), nj_history$middle_name)
# If suffix is not NA and is equal to "Jr", "Sr", "Jr.","JR.","SR.","II","IV","Sr.", or "V" 
# then delete from suffix column
nj_history$suffix <- ifelse(nj_history$suffix %in% c("Jr", "Sr", "Jr.","JR.","SR.","II","IV","Sr.", "V"), nj_history$suffix,NA)
# Change JR. to Jr. and SR. to Sr. in the suffix column
nj_history$suffix <- gsub("JR.", "Jr.", nj_history$suffix)
nj_history$suffix <- gsub("SR.", "Sr.", nj_history$suffix)
# Reassemble the full name from first_name, middle_name, last_name, and suffix
nj_history$full_name <- paste(nj_history$first_name, ifelse(is.na(nj_history$middle_name),"",nj_history$middle_name), nj_history$last_name, ifelse(is.na(nj_history$suffix),"",nj_history$suffix), sep = " ")
# Use squish to remove extra spaces
nj_history$full_name <- str_squish(nj_history$full_name)
#Drop rest_name
nj_history <- nj_history %>% select(-rest_name)

# Now merge the cleaned work history data into the index template
nj_officers_index <- bind_rows(template_index,nj_history)

# Export CSV of officer work history index for project
nj_officers_index %>% write_csv(nj_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
nj_officers_index <- nj_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
nj_officers_index %>% write_csv(nj_index)    


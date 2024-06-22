# Load required libraries
library(tidyverse)
library(lubridate)
library(readxl)
library(janitor)

# Clear workspace
rm(list = ls())

# Define root directory and output directory
root_dir = getwd()
output_dir = "data/processed/"

# Define paths to the source Excel file from state of Arizona
employment_file = "data/source/006_PR_2023_0413_AllOfficers_w_AppointmentsAndFinalActions.xlsx"

# Define paths to the output CSV files
az_index = "data/processed/az-2023-index.csv"
az_index_enhanced = "data/processed/az-2023-index-enhanced.csv"
az_original_employment = "data/processed/az-2023-original-employment.csv"

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

# Import the Excel files, converts date columns with hard NULL values to NA.
# The janitor::clean_names() function is used to clean up the column names.
az_history <- read_excel(employment_file, 
                         col_types = c("text", "text", "text","date","date","text","text","text",
                                       "date", "text", "text", "text")) %>% janitor::clean_names()
# name columns for consistency with template index
colnames(az_history) <- c("person_nbr","full_name","agency","start_date","end_date","rank",
                          "current_certificate_status","last_action","date_last_action","case_numbers",
                          "final_actions","final_action_dates")

# Output original employment data as CSV
write_csv(az_history, az_original_employment)

# Prepare the index consistent with other states' officer work history files
# Drop columns 8-12 that are not needed for the officer index for AZ
az_history <- az_history %>% select(-c("last_action","date_last_action","case_numbers","final_actions","final_action_dates"))

# Change the full_name to title case
az_history$full_name <- str_to_title(az_history$full_name)
# Extract last name from everything prior to the first comma
az_history$last_name <- gsub(",.*", "", az_history$full_name)
# Assign rest_name from everything after the first ", "
az_history$rest_name <- gsub(".*, ", "", az_history$full_name)
# Split rest name into tentative component pieces
split_names <- strsplit(az_history$rest_name, " ")
# Temporarily assign elements from the split name to new columns
az_history$first_name <- sapply(split_names, '[', 1)
az_history$middle_name <- sapply(split_names, '[', 2)
az_history$suffix <- sapply(split_names, '[', 3)

# Clean up inconsistent name part fields after manual testing and checks to ID tasks needed

# If suffix is not NA and is not equal to "Jr","II" or "III" 
# then append to middle_name and delete it from the suffix
az_history$middle_name <- ifelse(is.na(az_history$suffix), az_history$middle_name, paste(az_history$middle_name, az_history$suffix, sep = " "))
az_history$suffix <- ifelse(az_history$suffix %in% c("Jr","II","III"), az_history$suffix, NA)
# If there is " Jr" in the last name column, remove it from the last name column and append it to the suffix column
az_history$suffix <- ifelse(grepl(" Jr", az_history$last_name), "Jr", az_history$suffix)
az_history$last_name <- gsub(" Jr", "", az_history$last_name)
# If there is a Jr in the middle name, remove it from the middle name column 
# and append it to the suffix column, ignoring case
az_history$suffix <- ifelse(grepl("Jr", az_history$middle_name, ignore.case = TRUE), "Jr", az_history$suffix)
az_history$middle_name <- gsub("Jr", "", az_history$middle_name, ignore.case = TRUE)
# Fix oddly formatted names individually after research to verify
az_history$first_name[az_history$person_nbr == 15416] <- "Santiago"
az_history$middle_name[az_history$person_nbr == 15416] <- NA
az_history$last_name[az_history$person_nbr == 15416] <- "Renteria"
az_history$suffix[az_history$person_nbr == 15416] <- "Jr"
# If there is " Ii" or " Iii" in the last name column, remove it from the last name column and append it to the suffix column
az_history$suffix <- ifelse(grepl(" Iii", az_history$last_name), "III", az_history$suffix)
az_history$last_name <- gsub(" Iii", "", az_history$last_name)
az_history$suffix <- ifelse(grepl(" Ii", az_history$last_name), "II", az_history$suffix)
az_history$last_name <- gsub(" Ii", "", az_history$last_name)

# Reassemble the full name from first_name, middle_name, last_name, and suffix
az_history$full_name <- paste(az_history$first_name, ifelse(is.na(az_history$middle_name),"",az_history$middle_name), az_history$last_name, ifelse(is.na(az_history$suffix),"",az_history$suffix), sep = " ")
# Use squish to remove extra spaces
az_history$full_name <- str_squish(az_history$full_name)
# Drop rest_name
az_history <- az_history %>% select(-rest_name)

# Now merge the cleaned Arizona data into the index template
az_officers_index <- bind_rows(template_index,az_history)

# Export csv of work history index for project
az_officers_index %>% write_csv(az_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
az_officers_index <- az_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
az_officers_index %>% write_csv(az_index)     




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

# Define the paths to the input Excel files from state of SC
persons_file = "data/source/Export_Officer_Info_2023_07_24.xlsx"
licenses_file = "data/source/Export_Certification_2023_07_24.xlsx"
employment_file = "data/source/Export_Employment_Officer_2023_07_24.xlsx"

# Define the paths to the output CSV files
sc_index = "data/processed/sc-2023-index.csv"
sc_index_enhanced = "data/processed/sc-2023-index-enhanced.csv"
sc_original_persons = "data/processed/sc-2023-original-officers.csv"
sc_original_licenses = "data/processed/sc-2023-original-licenses.csv"
sc_original_employment = "data/processed/sc-2023-original-employment.csv"

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
# Also convert SC's placeholder for null (1/1/1111) to NA.
# The janitor::clean_names() function is used to clean up the column names.
sc_history <- read_excel(employment_file, 
                         col_types = c("text", "text", "text", 
                                       "text", "text", "date", "date")) %>% janitor::clean_names()
sc_officers <- read_excel(persons_file, 
                          col_types = c("text", "text", "text", 
                                        "text", "text", "text", "date", "text", 
                                        "text", "text")) %>% janitor::clean_names()
sc_licenses <- read_excel(licenses_file, 
                          col_types = c("text", "text", "text", 
                                        "text", "text", "text", "date", "date")) %>% janitor::clean_names()

# Rename the columns to be consistent with the index template.
# The state of SC's academy id is used as the person number.
colnames(sc_officers) <- c("full_name","last_name","first_name","middle_name",
                           "person_nbr","agency",
                           "last_hired_date","employment_status",
                           "gender","race")
colnames(sc_licenses) <- c("person_nbr","last_name","first_name","middle_name",
                           "license_type","license_status",
                           "issued_date","expiration_date")
colnames(sc_history) <- c("person_nbr","last_name","first_name","middle_name",
                          "agency","start_date","end_date")

# Convert the date columns to the YYYY-MM-DD format we are using in all indexes; using ymd from lubridate
sc_officers$last_hired_date <- sc_officers$last_hired_date %>% ymd
sc_history$start_date <- sc_history$start_date %>% ymd
sc_history$end_date <- sc_history$end_date %>% ymd
sc_licenses$issued_date <- sc_licenses$issued_date %>% ymd
sc_licenses$expiration_date <- sc_licenses$expiration_date %>% ymd

# Export the original dataframes as CSV files
sc_officers %>% write_csv(sc_original_persons)
sc_licenses %>% write_csv(sc_original_licenses)
sc_history %>% write_csv(sc_original_employment)

# Create the officers index of work history. 
# This involves several steps, including creating a suffix field, creating a new full name field, and joining the work history to the officers index.
# Start index with core/unique person data and standardize names
sc_officers_index <- sc_officers %>% select(person_nbr, full_name, first_name, middle_name, last_name,employment_status,race,gender)

# Create a suffix field in sc_officers that is bank for now
sc_officers_index$suffix <- NA
# Populate the suffix field in sc_officers with the characters after the last space in full_name, but only if the characters are II, III, Jr., Sr.
sc_officers_index$suffix <- ifelse(grepl(" II$", sc_officers_index$full_name), "II", sc_officers_index$suffix)
sc_officers_index$suffix <- ifelse(grepl(" III$", sc_officers_index$full_name), "III", sc_officers_index$suffix)
sc_officers_index$suffix <- ifelse(grepl(" Jr.$", sc_officers_index$full_name), "Jr.", sc_officers_index$suffix)
sc_officers_index$suffix <- ifelse(grepl(" Sr.$", sc_officers_index$full_name), "Sr.", sc_officers_index$suffix)
# Create a new_full_name field that combines first, middle, last names
sc_officers_index$new_full_name <- paste(sc_officers_index$first_name, ifelse(is.na(sc_officers_index$middle_name),"",sc_officers_index$middle_name), sc_officers_index$last_name, sep = " ")
# Now add the suffix to the new_full_name if it is not NA
sc_officers_index$new_full_name <- ifelse(is.na(sc_officers_index$suffix), sc_officers_index$new_full_name, paste(sc_officers_index$new_full_name, sc_officers_index$suffix, sep = " "))
# Trim any extra leading spaces, trailing spaces or double spaces
sc_officers_index$new_full_name <- sc_officers_index$new_full_name %>% str_squish()
# Replace full_name with new_full_name contents and drop new_full_name
sc_officers_index$full_name <- sc_officers_index$new_full_name
sc_officers_index <- sc_officers_index %>% select(-new_full_name)

# Add columns about license type, status and dates to the sc_officers_index
sc_officers_index <- left_join(sc_officers_index, sc_licenses %>% select(person_nbr, license_type, license_status, issued_date, expiration_date), by = "person_nbr")

# Before joining to history, do some cleanup of the names in the history file to same format of officers file
# This is because some officers in the history file are not in the licenses or persons file provided by South Carolina
sc_history$full_name <- paste(sc_history$first_name, ifelse(is.na(sc_history$middle_name),"",sc_history$middle_name), sc_history$last_name, sep = " ")
sc_history$full_name <- sc_history$full_name %>% str_squish()

# Join work history data to the sc_officers_index
sc_officers_index <- left_join(sc_history,sc_officers_index, by = "person_nbr")

# Series of steps to replace slightly less consistent names in the work history file with more consistent names in the officers file, where available
# In some cases of older records (presumably retired or departed officers) there is no correlating record in the officer/licenses data provided by South Carolina
# We are following up with SC about that, but using all/best available data provided so far
sc_officers_index$full_name <- ifelse(is.na(sc_officers_index$full_name.y), sc_officers_index$full_name.x, sc_officers_index$full_name.y)
sc_officers_index$first_name <- ifelse(is.na(sc_officers_index$first_name.y), sc_officers_index$first_name.x, sc_officers_index$first_name.y)
sc_officers_index$middle_name <- ifelse(is.na(sc_officers_index$middle_name.y), sc_officers_index$middle_name.x, sc_officers_index$middle_name.y)
sc_officers_index$last_name <- ifelse(is.na(sc_officers_index$last_name.y), sc_officers_index$last_name.x, sc_officers_index$last_name.y)

# Reorder columns to more closely match the template, drop the redundant columns, and rename columns for clarity
sc_officers_index <- sc_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name,
                                                  suffix, agency, license_type, start_date, end_date,
                                                  license_status,issued_date,expiration_date)
# Rename license_type as type for consistency
sc_officers_index <- sc_officers_index %>% rename(type = license_type)
# Rename issued_date as license_issued_date for clarity
sc_officers_index <- sc_officers_index %>% rename(current_license_issued_date = issued_date)
# Rename expiration_date as license_expiration_date for clarity
sc_officers_index <- sc_officers_index %>% rename(current_license_expiration_date = expiration_date)
# Rename license_status as current_license_status for clarity
sc_officers_index <- sc_officers_index %>% rename(current_license_status = license_status)

# Now merge the cleaned South Carolina data into the index template
sc_officers_index <- bind_rows(template_index,sc_officers_index)

# Export csv of enhanced work history index for project
sc_officers_index %>% write_csv(sc_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
sc_officers_index <- sc_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
sc_officers_index %>% write_csv(sc_index)                             
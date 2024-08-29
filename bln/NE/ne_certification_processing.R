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
employment_file = "data/source/FOIA_Request_3102023.xlsx"

# Define paths to the output CSV files
ne_index = "data/processed/ne-2023-index.csv"
ne_original_employment = "data/processed/ne-2023-original-employment.csv"

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
# Import the excel file provided by state of Nebraska
# Renamed from dropbox Copy_of_FOIA_Request_3-10-23 to nebraska_officers_031023.xlsx
# Date columns with hard NULL value will convert to NA
ne_officers <- read_excel(employment_file,
                          col_types = c("text", "text", "text", 
                                        "text", "text", "text", "text", "date", 
                                        "date", "numeric", "text", "text", 
                                        "text", "text", "text", "text", "text", 
                                        "text", "text", "text", "text", "text", 
                                        "text", "text", "text", "text", "text", 
                                        "text", "text", "text", "text", "text", 
                                        "text", "text", "text", "text")) %>% janitor::clean_names()

# Export the original officers file as a CSV
ne_officers %>% write_csv(ne_original_employment)

# Filter out columns not needed for index; they'll remain in the raw data release files
ne_officers <- ne_officers %>% select(1,3:10,13,16,36)

# Initial rename of columns to be consistent with template
colnames(ne_officers) <- c("person_nbr","full_name","last_name","middle_name","first_name",
                           "status","earliest_hire_date","sworn_date",
                           "age","rank","agency","agency_list")

# Need to decide whether to filter this index to only active officers

# For type converting all with values to "Police Officer" because file contains all police officers
# For rank, using state's rank column as is
ne_officers$type <- "Police Officer"

# Clean up date columns 
ne_officers$earliest_hire_date <- substr(ne_officers$earliest_hire_date,1,10) %>% ymd
ne_officers$sworn_date <- substr(ne_officers$sworn_date,1,10) %>% ymd

# In agency list field, replace "@" character with ", "
# This is a complete list of agencies for this officer, including the first agency listed in the agency field
ne_officers$agency_list <- gsub("@",", ",ne_officers$agency_list)

# Create a suffix field that extracts the suffix from the last name field
#ne_officers$last_name <- gsub("\\s+", " ", ne_officers$last_name)
#ne_officers$suffix <- ifelse(grepl("\\s", ne_officers$last_name), sub(".+\\s", "", ne_officers$last_name), "")

ne_officers$ suffix <- NA
# If there is " Jr" in the last name column, regardless of case, 
# then remove it from the last name column and append it to the suffix column
ne_officers$suffix <- ifelse(grepl(" Jr.", ne_officers$last_name, ignore.case = TRUE), "Jr.", ne_officers$suffix)
ne_officers$last_name <- gsub(" Jr.", "", ne_officers$last_name, ignore.case = TRUE)
# Repeat for " Jr."
ne_officers$suffix <- ifelse(grepl(" Jr", ne_officers$last_name, ignore.case = TRUE), "Jr.", ne_officers$suffix)
ne_officers$last_name <- gsub(" Jr", "", ne_officers$last_name, ignore.case = TRUE)
# Repeat for " Sr."
ne_officers$suffix <- ifelse(grepl(" Sr.", ne_officers$last_name, ignore.case = TRUE), "Sr.", ne_officers$suffix)
ne_officers$last_name <- gsub(" Sr.", "", ne_officers$last_name, ignore.case = TRUE)
# Repeat for " Sr"
ne_officers$suffix <- ifelse(grepl(" Sr", ne_officers$last_name, ignore.case = TRUE), "Sr.", ne_officers$suffix)
ne_officers$last_name <- gsub(" Sr", "", ne_officers$last_name, ignore.case = TRUE)
# Repeat for " III"
ne_officers$suffix <- ifelse(grepl(" III", ne_officers$last_name), "III", ne_officers$suffix)
ne_officers$last_name <- gsub(" III", "", ne_officers$last_name)
# Repeat for " II"
ne_officers$suffix <- ifelse(grepl(" II", ne_officers$last_name), "II", ne_officers$suffix)
ne_officers$last_name <- gsub(" II", "", ne_officers$last_name)
# Repeat for " IV"
ne_officers$suffix <- ifelse(grepl(" IV", ne_officers$last_name), "IV", ne_officers$suffix)
ne_officers$last_name <- gsub(" IV", "", ne_officers$last_name)
# Repeat for " Jr." but in the first name field
ne_officers$suffix <- ifelse(grepl(" Jr", ne_officers$first_name, ignore.case = TRUE), "Jr.", ne_officers$suffix)
ne_officers$first_name <- gsub(" Jr", "", ne_officers$first_name, ignore.case = TRUE)
# Repeat for " III" but in the first name field
ne_officers$suffix <- ifelse(grepl(" III", ne_officers$first_name), "III", ne_officers$suffix)
ne_officers$first_name <- gsub(" III", "", ne_officers$first_name)
# use str_squish to remove leading and trailing whitespace in all name fields: last, first, middle and suffix
ne_officers$last_name <- str_squish(ne_officers$last_name)
ne_officers$first_name <- str_squish(ne_officers$first_name)
ne_officers$middle_name <- str_squish(ne_officers$middle_name)
ne_officers$suffix <- str_squish(ne_officers$suffix)

# Reassemble the full name from first_name, middle_name, last_name, and suffix
ne_officers$full_name <- paste(ne_officers$first_name, ifelse(is.na(ne_officers$middle_name),"",ne_officers$middle_name), ne_officers$last_name, ifelse(is.na(ne_officers$suffix),"",ne_officers$suffix), sep = " ")
# Use squish to remove extra spaces
ne_officers$full_name <- str_squish(ne_officers$full_name)

# Now merge the cleaned Arizona data into the index template
ne_officers_index <- bind_rows(template_index,ne_officers)

# Export csv of work history index for project
ne_officers_index %>% write_csv(ne_index)

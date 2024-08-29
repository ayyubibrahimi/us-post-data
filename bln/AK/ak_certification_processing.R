# Import required libraries
library(tidyverse)
library(lubridate)
library(janitor)

# Clear the workspace to avoid conflicts with existing variables
rm(list = ls())

# Define the root directory and the output directory
root_dir = getwd()
output_dir = "data/processed/"

# Define the paths to the input Excel files
licenses_file = "data/source/APSC Certification 2017.csv"
persons_file = "data/source/APSC Current Officers.csv"
employment_change_file = "data/source/APSC Employment Status Changes since 2017.csv"

# Define the paths to the output CSV files
ak_index = "data/processed/ak-2023-index.csv"
ak_index_enhanced = "data/processed/ak-2023-index-enhanced.csv"
ak_original_employment_change = "data/processed/ak-2023-original-employment-change.csv"
ak_original_officers = "data/processed/ak-2023-original-officers.csv"
ak_original_certifications = "data/processed/ak-2023-original-certifications.csv"

# Create a template dataframe for the officers index. This will be used to ensure that the final dataframe has the correct structure.
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

# Import the CSV files
person_data <- read_csv(persons_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
employment_change <- read_csv(employment_change_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
licenses <- read_csv(licenses_file, col_types = cols(.default = col_character())) %>% janitor::clean_names() %>% select(1:13)

# Convert relevant date columns to YYYY-MM-DD format we are using in all indexes
# Leaving two expiration date fields as character because both includes text explanations for some officers
employment_change$last_hired_date <- mdy(employment_change$last_hired_date) %>% as.Date()
person_data$last_hired_date <- mdy(person_data$last_hired_date) %>% as.Date()
licenses$issued <- mdy(licenses$issued) %>% as.Date()
licenses$actioneffectivedate <- mdy(licenses$actioneffectivedate) %>% as.Date()

# Export a series of CSV files with the original data
# Because of some inconsistencies of some date fields and some being unneeded
# Leaving some date fields in raw character format to protect full information because of inconsistencies
write_csv(person_data, ak_original_officers)
write_csv(employment_change, ak_original_employment_change)
write_csv(licenses, ak_original_certifications)

# name columns for consistency
# persons and employment appear to be identical but let's confirm
colnames(person_data) <- c("last_name","first_name","person_nbr","agency","type","start_date",
                           "employment_status","last_action","date_last_action")

colnames(employment_change) <- c("last_name","first_name","person_nbr","agency","type","start_date",
                                 "employment_status","last_action","date_last_action")

colnames(licenses) <- c("last_name","first_name","person_nbr","agency","certification_type",
                        "certification","issued_date","expiration_date","certification_status",
                        "action_type","action_effective_date","action_expiration_date","action_status")


# Identify any officers in the person_data that are not in the employment_change file
# This will add any officers who've not had an employment change since 2017
# Because Alaska only provided current officers and status change since 2017
# This gets us the most complete index of officers' work histories possible - although not comprehensive
add_from_current <- person_data %>% anti_join(employment_change, by = "person_nbr")

# Create a roster from those two lists
alaska_roster <- bind_rows(employment_change, add_from_current)

# Create a full_name column from first_name and last_name
alaska_roster$full_name <- paste(alaska_roster$first_name, alaska_roster$last_name, sep = " ")

# Creates a series of dataframes to identify with a suspended, revoked or relinquished license
revoked_licenses <- licenses %>% filter(str_detect(certification_status, "Revok"))
surrendered_licenses <- licenses %>% filter(str_detect(certification_status, "Surrender"))

# Merge cleaned data with template index and sort by officer number, start date, and full name
ak_officers_index <- bind_rows(template_index,alaska_roster) %>% select(-employment_status)
ak_officers_index <- ak_officers_index %>% arrange(desc(person_nbr), desc(start_date), full_name)

# Export csv of work history index for project
ak_officers_index %>% write_csv(ak_index)

# Redo the index with additional fields for officers who have ever had a license revoked or surrendered
ak_officers_index <- bind_rows(template_index,alaska_roster)
ak_officers_index <- ak_officers_index %>% arrange(desc(person_nbr), desc(start_date), full_name)

# Adding a flag to Florida index file to indicate whether an officer has ever had their license revoked; for further investigating in raw license file
ak_officers_index$ever_revoked <- ifelse(ak_officers_index$person_nbr %in% revoked_licenses$person_nbr, TRUE, FALSE)
ak_officers_index$ever_surrendered <- ifelse(ak_officers_index$person_nbr %in% surrendered_licenses$person_nbr, TRUE, FALSE)

# Alaska officers' enhanced adding ever revoked fields
ak_officers_index %>% write_csv(ak_index_enhanced)




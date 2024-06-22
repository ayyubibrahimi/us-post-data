# Load required libraries
library(tidyverse)
library(lubridate)
library(janitor)
library(stringi)

# Clear workspace
rm(list = ls())

# Define root directory and output directory
root_dir = getwd()
output_dir = "data/processed/"

# Files originally delivered by state (FDLE) as an .accdb
# Separately converted to series of CSV files
# Define paths to the source files
persons_file = "data/source/person_data.csv"
licenses_file = "data/source/certificates.csv"
employment_file = "data/source/employment.csv"
agencies_file = "data/source/agencies.csv"
codes_files = "data/source/codes.csv"
complaints_file = "data/source/complaint.csv"
complaint_discipline_file = "data/source/complaint_discipline.csv"
complaint_offenses_file = "data/source/complaint_offenses.csv"
complaint_status_file = "data/source/complaint_status.csv"
complaint_activity_file = "data/source/complaint_activity.csv"

# Define the paths to the output CSV files
fl_index = "data/processed/fl-2023-index.csv"
fl_index_enhanced = "data/processed/fl-2023-index-enhanced.csv"
fl_original_persons = "data/processed/fl-2023-original-officers.csv"
fl_original_licenses = "data/processed/fl-2023-original-licenses.csv"
fl_original_employment = "data/processed/fl-2023-original-employment.csv"
fl_original_agencies = "data/processed/fl-2023-original-agencies.csv"
fl_original_codes = "data/processed/fl-2023-original-codes.csv"
fl_original_complaints = "data/processed/fl-2023-original-complaints.csv"
fl_original_complaint_discipline = "data/processed/fl-2023-original-complaint-discipline.csv"
fl_original_complaint_offenses = "data/processed/fl-2023-original-complaint-offenses.csv"
fl_original_complaint_status = "data/processed/fl-2023-original-complaint-status.csv"
fl_original_complaint_activity = "data/processed/fl-2023-original-complaint-activity.csv"

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

# Load each of the raw csv files with all columns defaulted to column type col_character
person_data <- read_csv(persons_file, col_types = cols(.default = col_character()),locale = locale(encoding = "ISO-8859-1")) %>% janitor::clean_names()
employment <- read_csv(employment_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
agencies <- read_csv(agencies_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
codes <- read_csv(codes_files, col_types = cols(.default = col_character())) %>% janitor::clean_names()
licenses <- read_csv(licenses_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
complaint <- read_csv(complaints_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
complaint_discipline <- read_csv(complaint_discipline_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
complaint_offenses <- read_csv(complaint_offenses_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
complaint_status <- read_csv(complaint_status_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
complaint_activity <- read_csv(complaint_activity_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()

# Export a series of CSV files with the original data
# Because of some inconsistencies of some date fields and some being unneeded
# Leaving date fields in raw character format to protect full information because of inconsistencies
write_csv(person_data, fl_original_persons)
write_csv(employment, fl_original_employment)
write_csv(licenses, fl_original_licenses)
write_csv(agencies, fl_original_agencies)
write_csv(codes, fl_original_codes)
write_csv(complaint, fl_original_complaints)
write_csv(complaint_discipline, fl_original_complaint_discipline)
write_csv(complaint_offenses, fl_original_complaint_offenses)
write_csv(complaint_status, fl_original_complaint_status)
write_csv(complaint_activity, fl_original_complaint_activity)

# Convert relevant date columns to YYYY-MM-DD format we are using in all indexes
# Using ymd function from lubridate package.
employment$employ_start_date <- mdy_hms(employment$employ_start_date) %>% as.Date()
employment$separation_date <- mdy_hms(employment$separation_date) %>% as.Date()
licenses$certificate_date <- mdy_hms(licenses$certificate_date) %>% as.Date()
licenses$certificate_exp_date <- mdy_hms(licenses$certificate_exp_date) %>% as.Date()
complaint$employ_start_date <- mdy_hms(complaint$employ_start_date) %>% as.Date()
complaint$case_opened_date <- mdy_hms(complaint$case_opened_date) %>% as.Date()
complaint$case_closed_date <- mdy_hms(complaint$case_closed_date) %>% as.Date()


# Combine employment, agencies, person_data, and codes dataframes to create start of work history index
florida_roster <- left_join(employment %>% select(2,3,5,6,7,8),
                            agencies %>% select (6,7), 
                            by = "agcy_nbr")
# Add relevant fields about individuals, joining on the state's unique identifier for officers
florida_roster <- left_join(florida_roster,
                            person_data %>% select (1,2,3,4,7), 
                            by = "person_nbr")
# Join with codes dataframe, filter by category and rename columns
florida_roster <- left_join(florida_roster,
                            codes %>% filter(category=="employ_class") %>% select (4,5), 
                            by = c("employ_class"="code_value")) %>%
  rename("type" = "code_description")
# Adding the reason for separation field
florida_roster <- left_join(florida_roster,
                            codes %>% filter(category=="separation_code") %>% select (4,5), 
                            by = c("separation_code"="code_value")) %>%
  rename("separation_reason" = "code_description")

# Clean up inconsistent name fields after manual testing and checks to ID tasks needed

# Split suffixes from last and first names
florida_roster <- florida_roster %>%
  mutate(suffix = ifelse(stri_detect_regex(last_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), stri_extract_last_regex(last_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), NA_character_),
         last_name = ifelse(stri_detect_regex(last_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), stri_replace_last_regex(last_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$", ""), last_name))
florida_roster <- florida_roster %>%
  mutate(suffix = ifelse(stri_detect_regex(first_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), stri_extract_last_regex(first_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), suffix),
         first_name = ifelse(stri_detect_regex(first_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$"), stri_replace_last_regex(first_name, "Jr$|Jr\\.$|Sr$|Sr\\.$|II$|III$|IV$|V$|XVI$", ""), first_name))

# Handle a few inconsistent special cases for suffixes
florida_roster <- florida_roster %>%
  mutate(suffix = ifelse(person_nbr == "391055", NA_character_, suffix),
         last_name = ifelse(person_nbr == "391055", "IV", last_name))
florida_roster <- florida_roster %>%
  mutate(suffix = ifelse(first_name == "Joseph Jr.", "Jr.", suffix),
         first_name = ifelse(first_name == "Joseph Jr.", "Joseph", first_name))
florida_roster <- florida_roster %>%
  mutate(suffix = ifelse(stri_detect_regex(last_name, "Blanford") & first_name == "Norris", "Jr. III", suffix),
         last_name = ifelse(stri_detect_regex(last_name, "Blanford") & first_name == "Norris", "Blanford", last_name))

# Clean up name part fields by removing scattered spaces and unneeded commas
florida_roster$last_name <- florida_roster$last_name %>% str_squish()
florida_roster$first_name <- florida_roster$first_name %>% str_squish()
florida_roster$last_name <- gsub(",", "", florida_roster$last_name)

# Create a new full name field consistent with the index files for other states in the project
florida_roster$full_name <- paste(florida_roster$first_name, ifelse(is.na(florida_roster$middle_name),"",florida_roster$middle_name), florida_roster$last_name, ifelse(is.na(florida_roster$suffix),"",florida_roster$suffix), sep=" ")
florida_roster$full_name <- florida_roster$full_name %>% str_squish()

# Rename and reformat columns to match the template index to be consistent with other states in project
florida_roster <- florida_roster %>% rename(agency = agcy_name, start_date = employ_start_date, end_date = separation_date)
florida_roster$birth_year <- as.numeric(florida_roster$birth_year)
florida_roster <- florida_roster %>% rename(year_of_birth = birth_year)
florida_roster <- florida_roster %>% select(-c(agcy_nbr, employ_class, separation_code))

# Add flags for license status for each officer
licenses_status <- licenses %>% select(person_nbr, certificate_nbr, certificate_status, certificate_date, certificate_exp_date)
licenses_status <- left_join(licenses_status,
                             codes %>% filter(category == "certificate_status") %>% select(code_value, code_description),
                             by = c("certificate_status" = "code_value")) %>%
  rename("status" = "code_description")
# Creates a series of dataframes to identify with a suspended, revoked or relinquished license
revoked_licenses <- licenses_status %>% filter(str_detect(status, "Revok"))
relinquished_licenses <- licenses_status %>% filter(str_detect(status, "Relinq"))
suspended_licenses <- licenses_status %>% filter(str_detect(status, "Susp"))

# Adding a flag to Florida index file to indicate whether an officer has ever had their license revoked; for further investigating in raw license file
florida_roster$ever_revoked <- ifelse(florida_roster$person_nbr %in% revoked_licenses$person_nbr, TRUE, FALSE)

# Merge cleaned data with template index and sort by officer number, start date, and full name
fl_officers_index <- bind_rows(template_index,florida_roster)
fl_officers_index <- fl_officers_index %>% arrange(desc(person_nbr), desc(start_date), full_name)

# Export csv of work history index for project
fl_officers_index %>% write_csv(fl_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
fl_officers_index <- fl_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
fl_officers_index %>% write_csv(fl_index)       




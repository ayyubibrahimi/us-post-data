# Load libraries
library(tidyverse)
library(lubridate)
library(readxl)
library(janitor)

# Clean workspace
rm(list = ls())

# Set working and output directories
root_dir = getwd()

# Identify paths for raw state Excel files to import
persons_file = "data/original/tx_servicerecords_03192024.xlsx"
licenses_file = "data/original/tx_licenses_03192024.xlsx"
#certifications_file = "/data/source/vt/Certifications.csv"

# Identify paths for output CSV files
tx_index = "data/processed/tx-2023-index.csv"
tx_index_enhanced = "data/processed/tx-2023-index-enhanced.csv"
tx_original_persons = "data/processed/tx-2023-original-persons.csv"
tx_original_licenses = "data/processed/tx-2023-original-licenses.csv"

# Create a template dataframe for the officers index. 
# This will be used to ensure that the final dataframe has the correct structure.
template_public <- data.frame("person_nbr" = character(0),
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

# Import Excel file for officers provided by state of Texas
# Date columns with hard NULL value will convert to NA
tx_officers <- read_excel(persons_file,
                          col_types = c("text", "text", "text",
                                        "text", "text", "numeric",
                                        "text", "text", "text",
                                        "text", "text", "date",
                                        "date","numeric"))
# Import Excel file for certificates provided by state of Texas
# Date columns with hard NULL value will convert to NA
tx_licenses <- read_excel(licenses_file,
                          col_types = c("text", "text", "text",
                                        "date", "text", "text",
                                        "text"))
# Note: This import fails to process seven dates; 
# Five that were NULL and two that had problem formats entered as 1881

# Initial rename of columns to be more consistent format with eventual work history index
# We are using state field appointment in rank column in index and license in type column in index
colnames(tx_officers) <- c("guid","first_name","middle_name","last_name",
                           "suffix","year_of_birth","appointment","county",
                           "agency","license","new_applicant",
                           "start_date","end_date","service_time_months")
colnames(tx_licenses) <- c("guid","license","license_action",
                           "action_date","action_notes",
                           "license_status_code","license_status")

# Properly format the date columns in both files
tx_officers$start_date <- substr(tx_officers$start_date,1,10) %>% ymd
tx_officers$end_date <- substr(tx_officers$end_date,1,10) %>% ymd
tx_licenses$action_date <- substr(tx_licenses$action_date,1,10) %>% ymd

# Standardize all the mismatched case formatting throughout both files
tx_officers$county <- str_to_title(tx_officers$county)
tx_officers$agency <- str_to_title(tx_officers$agency)
tx_officers$first_name <- str_to_title(tx_officers$first_name)
tx_officers$middle_name <- str_to_title(tx_officers$middle_name)
tx_officers$last_name <- str_to_title(tx_officers$last_name)
tx_licenses$action_notes <- str_to_title(tx_licenses$action_notes)

# Output processed original files as CSV files
tx_officers %>% write_csv(tx_original_persons)
tx_licenses %>% write_csv(tx_original_licenses)

# PREPARE INDEX FILE
# We will treat Texas license as type
# We will treat Texas appointment as rank
# We will use Texas' generated unique ID as the person_nbr
# Rename those three columns
tx_officers <- tx_officers %>% rename("person_nbr" = guid)
tx_officers <- tx_officers %>% rename("type" = license)
tx_officers <- tx_officers %>% rename("rank" = appointment)
tx_licenses <- tx_licenses %>% rename("person_nbr" = guid)

# If middle name is NA, convert to empty string
tx_officers$middle_name[is.na(tx_officers$middle_name)] <- ""
# If suffix is NA, convert to empty string
tx_officers$suffix[is.na(tx_officers$suffix)] <- ""
# Back up the raw suffix data from the original Texas file
# because it appears in some cases to contain a title, the balance of the middle name, or a suffix;
# saving it for reporting purposes; may or may not keep in processed index files since it's preserved in original csv files
tx_officers$suffix_raw <- tx_officers$suffix

# SUFFIX CLEANING
# Attempt to process and standardize the suffixes present;
# Only able to do so for those that are certain; otherwise removing non-suffix or other invalid values
# Clean non letter or digit characters out of suffix
tx_officers$suffix <- gsub("[^a-zA-Z0-9]","",tx_officers$suffix)
# Create a temporary table with all variations in the suffix field
suffixes <- tx_officers %>% group_by(suffix) %>% summarise(count=n())
# Clean up the suffix field to standardize and only include where it's clearly a suffix
# There are a small number of records in the raw data where it's not clear; those are converted to NA in this index
tx_officers$suffix <- case_when(
  tx_officers$suffix %in% c("Junio","Jr.5","Jr II","JR", "J R", "Jr", "jr", "JR`") ~ "Jr",
  tx_officers$suffix %in% c("SR", "S R", "Sr", "sr", "SR`") ~ "Sr",
  tx_officers$suffix %in% c("II","I1","II.", "I I","2","2nd") ~ "II",
  tx_officers$suffix %in% c("III", "iii","3rd", "3RD") ~ "III",
  tx_officers$suffix %in% c("I","i") ~ "I",
  tx_officers$suffix %in% c("iv","IV","IV.") ~ "IV",
  tx_officers$suffix %in% c("v","V") ~ "V",
  tx_officers$suffix == "VI" ~ "VI",
  tx_officers$suffix == "VII" ~ "VII",
  tx_officers$suffix == "VIII" ~ "VIII",
  TRUE ~ ""
)

# create a full name field
tx_officers$full_name <- paste(tx_officers$first_name, tx_officers$middle_name, tx_officers$last_name, ifelse(!is.na(tx_officers$suffix),tx_officers$suffix,"")) %>% trimws()

# Temporary reference table for all license types
types <- tx_officers %>% group_by(type) %>% summarise(count=n())

# Remove all records with a type including the word telecommunications
tx_officers <- tx_officers %>% filter(!grepl("telecommunications",type,ignore.case=TRUE))

# Now merge the cleaned Texas data into the work history index file
tx_officers_public <- bind_rows(template_public,tx_officers) %>% select(-new_applicant,-service_time_months,-suffix_raw)

# We are going to enhance the index file slightly to note whether a license has ever been revoked 
# As a potential flag to users of the work history file to look up that person_nbr in the licenses history file

# Filter the licenses table for any person_nbr where the license_action includes the string revoc or revok
# This will be used to identify any licenses that have been revoked
revoked_licenses <- tx_licenses %>% filter(grepl("revoc|revok",license_action,ignore.case=TRUE))
# Add a column called ever_revoked to the tx_officers_public dataframe that is TRUE if the person_nbr is in the revoked_licenses dataframe
tx_officers_public$ever_revoked <- ifelse(tx_officers_public$person_nbr %in% revoked_licenses$person_nbr, TRUE, FALSE)
# Now repeat to identify any licenses that have been surrendered
surrendered_licenses <- tx_licenses %>% filter(grepl("surrend",license_action,ignore.case=TRUE))
# Add a column called ever_surrendered to the tx_officers_public dataframe that is TRUE if the person_nbr is in the surrendered_licenses dataframe
tx_officers_public$ever_surrendered <- ifelse(tx_officers_public$person_nbr %in% surrendered_licenses$person_nbr, TRUE, FALSE)

# Export csv of work history index for project
tx_officers_public %>% write_csv(tx_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
tx_officers <- tx_officers_public %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
tx_officers %>% write_csv(tx_index)     





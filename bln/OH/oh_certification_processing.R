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

# Define paths to the source Excel file from state
employment_file = "data/source/Muckrock_PRR12536.xlsx"
decertified_file = "data/source/Decertified_and_Voluntary_Surrender_Officers_4-3-2023_3-31-31_PM.xlsx"

# Define paths to the output CSV files
oh_index = "data/processed/oh-2023-index.csv"
oh_index_enhanced = "data/processed/oh-2023-index-enhanced.csv"
oh_original_officers = "data/processed/oh-2023-original-officers.csv"
oh_original_employment = "data/processed/oh-2023-original-employment.csv"
oh_original_decertified = "data/processed/oh-2023-original-decertified.csv"

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
oh_history <- read_excel(employment_file, sheet = "Employments", 
                         col_types = c("text","text", "date", "text", "date", "date", 
                                       "text")) %>% janitor::clean_names()
# name columns for consistency with template index
colnames(oh_history) <- c("full_name","person_nbr","date_of_birth","agency","start_date","end_date","status")

oh_officers <- read_excel(employment_file, sheet = "Certificates",
                         col_types = c("text", "text", "date", 
                                       "text", "text", "date", "text")) %>% janitor::clean_names()
# name columns for consistency with template index
colnames(oh_officers) <- c("full_name","person_nbr","date_of_birth","ago_decertified_flag",
                          "ago_certificate_nbr","certification_date","type")

#Repeat for decertified officers
oh_decertified <- read_excel(decertified_file, sheet = 1,
                             col_types = c("skip", "skip", "date", 
                                           "text", "text", "text", "text", "text", 
                                           "text", "text"))
# name columns more consistently and clearly
colnames(oh_decertified) <- c("date_modified","full_name","first_name","middle_name","last_name","decertified_flag",
                           "voluntary_surrender","comments")

# Extract year of birth from date of birth in history and officer files before exporting to CSV
oh_history$year_of_birth <- year(oh_history$date_of_birth)
oh_officers$year_of_birth <- year(oh_officers$date_of_birth)
# Calculate age based on date of birth; point in time age based on processing date of files 2024-06-08
oh_officers$age <- as.numeric(difftime(Sys.Date(), oh_officers$date_of_birth, units = "days") / 365.25)
oh_officers$age <- floor(oh_officers$age)
oh_history$age <- as.numeric(difftime(Sys.Date(), oh_history$date_of_birth, units = "days") / 365.25)
oh_history$age <- floor(oh_history$age)
# Drop date of birth column
oh_history <- oh_history %>% select(-date_of_birth)
oh_officers <- oh_officers %>% select(-date_of_birth)
# Output original employment data as CSV
oh_history %>% select(-age) %>% write_csv(oh_original_employment)
oh_officers %>% select(-age) %>% write_csv(oh_original_officers)
write_csv(oh_decertified, oh_original_decertified)

######
# Start creating officer work history index consistent with other states in project
# Rename status column to rank for consistency with other states
oh_history <- oh_history %>% rename(rank = status)

# drop the time from start_date and end_date in history
oh_history$start_date <- as.Date(oh_history$start_date)
oh_history$end_date <- as.Date(oh_history$end_date)

# Backup original_full_name temporarily before cleaning and in case only way to match to decertification file later
oh_history$original_full_name <- oh_history$full_name
# Extract last name from everything prior to the first comma
oh_history$last_name <- gsub(",.*", "", oh_history$full_name)
# Assign rest_name from everything after the first ", "
oh_history$rest_name <- gsub(".*, ", "", oh_history$full_name)
# Use squish to remove some extraneous spaces
oh_history$rest_name <- str_squish(oh_history$rest_name)
# Split rest name into tentative component pieces
split_names <- strsplit(oh_history$rest_name, " ")
# Temporarily assign elements from the split name to new columns
oh_history$first_name <- sapply(split_names, '[', 1)
oh_history$middle_name <- sapply(split_names, '[', 2)
oh_history$suffix <- sapply(split_names, '[', 3)
# Anything in suffix at this point should be added back to middle name
oh_history$middle_name <- ifelse(is.na(oh_history$suffix), oh_history$middle_name, paste(oh_history$middle_name, oh_history$suffix, sep = " "))
# Remove any contents from suffix field
oh_history$suffix <- NA
# Clean up inconsistent name part fields after manual testing and checks to ID tasks needed
# If original_full_name includes ", Jr.," or ", Sr.," or ", II," or ", III," then assign to suffix
oh_history$suffix <- ifelse(grepl(", Jr.", oh_history$original_full_name), "Jr", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(", Sr.", oh_history$original_full_name), "Sr", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(", II,", oh_history$original_full_name), "II", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(", III,", oh_history$original_full_name), "III", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(", IV,", oh_history$original_full_name), "IV", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(", V,", oh_history$original_full_name), "V", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(" II", oh_history$original_full_name), "II", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(" III", oh_history$original_full_name), "III", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(" IV,", oh_history$original_full_name), "IV", oh_history$suffix)
oh_history$suffix <- ifelse(grepl(" V,", oh_history$original_full_name), "V", oh_history$suffix)
# Remove some suffixes from last_name if they remain there because of lack of comma
oh_history$last_name <- gsub(" Jr.", "", oh_history$last_name)
oh_history$last_name <- gsub(" Sr.", "", oh_history$last_name)
oh_history$last_name <- gsub(" II", "", oh_history$last_name)
oh_history$last_name <- gsub(" III", "", oh_history$last_name)
oh_history$last_name <- gsub(" IV", "", oh_history$last_name)
oh_history$last_name <- gsub(" V", "", oh_history$last_name)

# Reassemble the full name from first_name, middle_name, last_name, and suffix
oh_history$full_name <- paste(oh_history$first_name, ifelse(is.na(oh_history$middle_name),"",oh_history$middle_name), oh_history$last_name, ifelse(is.na(oh_history$suffix),"",oh_history$suffix), sep = " ")
# Use squish to remove extra spaces
oh_history$full_name <- str_squish(oh_history$full_name)
# Drop original_full_name, rest_name
oh_history <- oh_history %>% select(-original_full_name, -rest_name)

# Now merge the cleaned Arizona data into the index template
oh_officers_index <- bind_rows(template_index,oh_history)

# Export csv of work history index for project
oh_officers_index %>% write_csv(oh_index)



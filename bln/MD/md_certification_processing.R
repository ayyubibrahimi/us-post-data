# Load required libraries
library(tidyverse)
library(lubridate)
library(janitor)
library(stringr)

# Clear the workspace
rm(list = ls())

# Define root directory and output directory
root_dir = getwd()
output_dir = "data/processed/"

# Define the paths to the input/raw csv files from state of Illinois
persons_file = "data/source/certification_fullData_md.csv"
employment_file = "data/source/employment_history_fullData_md.csv"

# Define the paths to the output CSV files
md_index = "data/processed/md-2023-index.csv"
md_index_enhanced = "data/processed/md-2023-index-enhanced.csv"
md_original_persons = "data/processed/md-2023-original-officers.csv"
md_original_employment = "data/processed/md-2023-original-employment.csv"

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
person_data <- read_csv(persons_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()
employment <- read_csv(employment_file, col_types = cols(.default = col_character())) %>% janitor::clean_names()

# Convert relevant date columns to YYYY-MM-DD format we are using in all indexes
# Using ymd function from lubridate package.
employment$date <- mdy(employment$date) %>% as.Date()
person_data$date <- mdy(person_data$date) %>% as.Date()
person_data$certified <- mdy(person_data$certified) %>% as.Date()
person_data$expires <- mdy(person_data$expires) %>% as.Date()
person_data$probation <- mdy(person_data$probation) %>% as.Date()
# Rename employment history date field as start_date
employment <- employment %>% rename(start_date = date)

# Export the original files as CSV format
write_csv(person_data, md_original_persons)
write_csv(employment, md_original_employment)

# Now begin building the state index consistent with the other states in the project
# Function to convert the state's natural language description of service time to numerical number of days
convert_to_days <- function(time_description) {
  # Extract the number of years and days from the string
  years_days <- str_extract_all(time_description, "\\d+") %>% unlist() %>% as.numeric()
  
  # Convert the years to days and add the number of days
  total_days <- years_days[1]*365 + years_days[2]
  
  return(total_days)
}

# Create a new field called service_days
employment$service_days <- employment$service %>% map_dbl(convert_to_days)
# Create an end_date
# Add the number of days to the date
employment$end_date <- employment$start_date + days(employment$service_days)

# Standardizing the names of the employment file with the index template column names
employment <- employment %>% rename(rank = pos_rank)
employment <- employment %>% rename(type = level)
employment <- employment %>% rename(agency = police_department)
employment <- employment %>% rename(person_nbr = id_number)
# id_number to person_nbr in person_data
person_data <- person_data %>% rename(person_nbr = id_number)

# Merge the person data with the employment data
md_history <- employment %>% select(-service, -service_days)


# Replace any double periods inside the name field with a comma
md_history$name <- gsub("\\.\\.", ",", md_history$name)
# Extract last name from everything prior to the first comma
md_history$last_name <- gsub(",.*", "", md_history$name)
# Populate rest_name from everything after the first ", "
md_history$rest_name <- gsub(".*, ", "", md_history$name)

# Split the name parts for further cleaning and processing
split_names <- strsplit(md_history$rest_name, " ")
# Assign the corresponding elements from the split name to new columns
md_history$first_name <- sapply(split_names, '[', 1)
md_history$middle_name <- sapply(split_names, '[', 2)
md_history$suffix <- sapply(split_names, '[', 3)

# If suffix is not NA and not equal to "Jr", "Sr", "Jr.","JR.","SR.","II","III"IV","Sr.", or "V" 
# then append to middle_name column
md_history$middle_name <- ifelse(!is.na(md_history$suffix) & !md_history$suffix %in% c("Jr", "Sr", "Jr.","JR.","SR.","II","III","IV","Sr.", "V"), paste(md_history$middle_name, md_history$suffix), md_history$middle_name)
# If suffix is not NA and is equal to "Jr", "Sr", "Jr.","JR.","SR.","II","III","IV","Sr.", or "V" 
# then delete from suffix column
md_history$suffix <- ifelse(md_history$suffix %in% c("Jr", "Sr", "Jr.","JR.","SR.","II","III","IV","Sr.", "V"), md_history$suffix,NA)

# If there is " Jr." in the last name column, remove it from the last name column and append it to the suffix column
md_history$suffix <- ifelse(grepl(" Jr.", md_history$last_name), "Jr.", md_history$suffix)
md_history$last_name <- gsub(" Jr.","", md_history$last_name)
# If there is a Jr in the last name, remove it from the last name column 
# and append it to the suffix column, ignoring case
md_history$suffix <- ifelse(grepl("Jr", md_history$last_name, ignore.case = TRUE), "Jr.", md_history$suffix)
md_history$last_name <- gsub("Jr", "", md_history$last_name, ignore.case = TRUE)
# If there is a " Sr." in the last name column, remove it from the last name column and append it to the suffix column
md_history$suffix <- ifelse(grepl(" Sr.", md_history$last_name), "Sr.", md_history$suffix)
md_history$last_name <- gsub(" Sr.", "", md_history$last_name)
# If there is a " Sr" in the last name column, remove it from the last name column and append it to the suffix column
md_history$suffix <- ifelse(grepl(" Sr", md_history$last_name), "Sr.", md_history$suffix)
md_history$last_name <- gsub(" Sr", "", md_history$last_name)
# If there is " Ii" or " Iii" in the last name column, remove it from the last name column and append it to the suffix column
md_history$suffix <- ifelse(grepl(" III", md_history$last_name), "III", md_history$suffix)
md_history$last_name <- gsub(" III", "", md_history$last_name)
md_history$suffix <- ifelse(grepl(" II", md_history$last_name), "II", md_history$suffix)
md_history$last_name <- gsub(" II", "", md_history$last_name)
md_history$suffix <- ifelse(grepl(" IV", md_history$last_name), "IV", md_history$suffix)
md_history$last_name <- gsub(" IV", "", md_history$last_name)
# If the last two characters are space and then capital V, remove it from the last name column and append it to the suffix column
md_history$suffix <- ifelse(grepl(" V$", md_history$last_name), "V", md_history$suffix)
md_history$last_name <- gsub(" V$", "", md_history$last_name)

# Reassemble the full name from first_name, middle_name, last_name, and suffix
md_history$full_name <- paste(md_history$first_name, ifelse(is.na(md_history$middle_name),"",md_history$middle_name), md_history$last_name, ifelse(is.na(md_history$suffix),"",md_history$suffix), sep = " ")
# Use squish to remove extra spaces
md_history$full_name <- str_squish(md_history$full_name)
# Drop rest_name
md_history <- md_history %>% select(-rest_name,-name)

# Merge cleaned data with template index and sort by officer number, start date, and full name
md_officers_index <- bind_rows(template_index,md_history)
md_officers_index <- md_officers_index %>% arrange(desc(person_nbr), desc(start_date), full_name)

# Export csv of work history index for project
md_officers_index %>% write_csv(md_index_enhanced)

# Remove extra columns and export csv of standard work history index for project
md_officers_index <- md_officers_index %>% select(person_nbr, full_name, first_name, middle_name, last_name, suffix, year_of_birth, age, agency, type, rank, start_date, end_date)

# Export csv of standard work history index for project
md_officers_index %>% write_csv(md_index)       






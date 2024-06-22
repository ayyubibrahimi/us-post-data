### Processing OR police certification

# check for pacman package, install if not
if(!"pacman" %in% rownames(installed.packages())) {
  install.packages("pacman")
}

# load libraries
pacman::p_load(dplyr, tidyr, readr, lubridate, stringr, janitor, rio)

# clean working environment
rm(list = ls())

# set directories
root_dir = getwd()
output_dir = "/data/processed/or/"


# CSV files to import
employees_file = "/data/source/or/Employees.csv"
employment_file = "/data/source/or/Employment.csv"
certifications_file = "/data/source/or/Certifications.csv"
training_file = "/data/source/or/Training.csv"
employees_archive_file = "/data/source/or/Employees_archive.csv"
employment_archive_file = "/data/source/or/Employment_archive.csv"
certifications_archive_file = "/data/source/or/Certifications_archive.csv"
training_archive_file = "/data/source/or/Training_archive.csv"


# output CSV files
or_index = "or-2023-index.csv"
or_original_employees = "or-2023-original-employees.csv"
or_original_employment = "or-2023-original-employment.csv"
or_original_certifications = "or-2023-original-certifications.csv"
or_original_training = "or-2023-original-training.csv"


# import data, clean column names, uppercase data, convert dates, dedup 
# select is getting rid of any private personal info

# employees_file
or_employees_df <- import(paste0(root_dir,employees_file), colClasses = c(Age="character")) %>% 
  clean_names() %>% 
  bind_rows(import(paste0(root_dir,employees_archive_file), colClasses = c(Age="character")) %>% 
              clean_names() %>% 
              rename(dpsst_number = dpsst)) %>% 
  distinct() %>% 
  filter(!is.na(emp_rec_no)) %>% 
  rename(c(emp_id = dpsst_number)) %>% 
  unite('full_name', c('first_name',
                       'init',
                       'last_name',
                       'suffix'), sep = " ", remove = FALSE, na.rm = TRUE) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  mutate(across(c(full_name:suffix), ~str_squish(.))) %>% 
  mutate(across(c(full_name:suffix), ~str_replace(.,"\\.", ""))) %>%
  mutate(add_date = paste(str_split_i(add_date, "/", 3),
                          str_pad(str_split_i(add_date, "/", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(add_date, "/",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(chg_date = paste(str_split_i(chg_date, "/", 3),
                          str_pad(str_split_i(chg_date, "/", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(chg_date, "/",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(across(c(add_date, chg_date), ~str_replace(.,"NA-00-NA", ""))) %>% 
  mutate(age = as.numeric(age)) %>% 
  select(!c(driver_license_no, dl_state, dl_expired, pin_no, file_no, 
            address_line_1, address_line_2, city, state, zip_code, county, 
            county_description, region, region_description, mail_loc, home_phone,
            work_phone, ext, mobile_phone, work_mobile, pager, email,
            user_defined_item_number_1, user_defined_item_number_1_description, user_defined_item_number_2, 
            user_defined_item_number_2_description, contact_name_number_1, relat_number_1, relationship_number_1_description,
            contact_number_1_phone, contact_name_number_2, relat_number_2, relationship_number_2_description, 
            contact_number_2_phone))%>% 
  arrange(emp_rec_no)

# employment_file.  
or_employment_df <- import(paste0(root_dir,employment_file)) %>% 
  clean_names() %>% 
  bind_rows(import(paste0(root_dir,employment_archive_file)) %>% 
              clean_names()) %>% 
  select(-starts_with("V")) %>% 
  distinct() %>% 
  filter(!is.na(emp_rec_no)) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>%
  mutate(across(c(first_name:suffix), ~str_squish(.))) %>% 
  mutate(across(c(first_name:suffix), ~str_replace(.,"\\.", ""))) %>%
  mutate(act_date = paste(str_split_i(act_date, "-", 3),
                          str_pad(str_split_i(act_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(act_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(add_date = paste(str_split_i(add_date, "-", 3),
                          str_pad(str_split_i(add_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(add_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(chg_date = paste(str_split_i(chg_date, "-", 3),
                          str_pad(str_split_i(chg_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(chg_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(across(c(act_date, act_date, chg_date), ~str_replace(.,"NA-00-NA", ""))) %>% 
  arrange(emp_rec_no, agency_id, act_date)

# certifications_file
or_certifications_df <- import(paste0(root_dir,certifications_file), colClasses = c(`Cert. No.`="character")) %>% 
  clean_names() %>% 
  bind_rows(import(paste0(root_dir,certifications_archive_file), colClasses = c(`Cert. No.`="character")) %>% 
              clean_names()) %>% 
  distinct() %>% 
  filter(!is.na(emp_rec_no)) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  mutate(across(c(first_name:suffix), ~str_squish(.))) %>% 
  mutate(across(c(first_name:suffix), ~str_replace(.,"\\.", ""))) %>%
  mutate(stat_date = paste(str_split_i(stat_date, "-", 3),
                          str_pad(str_split_i(stat_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(stat_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(cert_date = paste(str_split_i(cert_date, "-", 3),
                           str_pad(str_split_i(cert_date, "-", 1), 2, side="left", pad="0"),
                           str_pad(str_split_i(cert_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(exp_date = paste(str_split_i(exp_date, "-", 3),
                           str_pad(str_split_i(exp_date, "-", 1), 2, side="left", pad="0"),
                           str_pad(str_split_i(exp_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(add_date = paste(str_split_i(add_date, "-", 3),
                          str_pad(str_split_i(add_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(add_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(chg_date = paste(str_split_i(chg_date, "-", 3),
                          str_pad(str_split_i(chg_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(chg_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(across(c(stat_date, cert_date, exp_date, add_date, chg_date), ~str_replace(.,"NA-00-NA", ""))) %>% 
  arrange(emp_rec_no)

# training_file (~3.5 million rows)
or_training_df <- import(paste0(root_dir,training_file), colClasses = c(`Inst. ID`="character")) %>% 
  clean_names() %>% 
  bind_rows(import(paste0(root_dir,training_archive_file), colClasses = c(`Inst. ID`="character")) %>% 
              clean_names()) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  mutate(across(c(first_name:suffix), ~str_squish(.))) %>% 
  mutate(across(c(first_name:suffix), ~str_replace(.,"\\.", ""))) %>%
  mutate(trn_date = paste(str_split_i(trn_date, "-", 3),
                           str_pad(str_split_i(trn_date, "-", 1), 2, side="left", pad="0"),
                           str_pad(str_split_i(trn_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(add_date = paste(str_split_i(add_date, "-", 3),
                          str_pad(str_split_i(add_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(add_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(chg_date = paste(str_split_i(chg_date, "-", 3),
                          str_pad(str_split_i(chg_date, "-", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(chg_date, "-",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(across(c(trn_date, add_date, chg_date), ~str_replace(.,"NA-00-NA", ""))) %>% 
  arrange(emp_rec_no, trn_date, crse_id)


# build the index file 
#start with employees_file
or_name_index_df <- or_employees_df %>% 
  transmute(person_nbr = emp_rec_no,
            full_name,
            last_name,
            first_name,
            middle_name = NA,
            middle_initial = init,
            suffix,
            birth_year = NA,
            age, 
            type = NA) %>% 
  distinct() 

# build the work history data with employment_file
# get the actions that would indicate the start date for the agency
or_history_start_df <- or_employment_df %>% 
  filter(action_description %in% c(
    "ACTIVE","CERTIFICATION REINSTATED","HIRED","PROMOTION","RECLASSIFICATION","REINSTATED",
    "RETURN FROM LEAVE OF ABSENCE","RETURN FROM MILITARY LOA","TRANSFERRED"
  )) %>% 
  group_by(emp_rec_no, agency_name, rank_description) %>% 
  summarize(
    start_date = min(act_date)
  ) %>% 
  ungroup() %>% 
  distinct()

# get the actions that indicate the end date for the agency
or_history_end_df <- or_employment_df %>% 
  filter(action_description %in% c(
    "CERTIFICATION DENIED","CERTIFICATION REVOKED","CERTIFICATION SUSPENDED","DECEASED","DEMOTION",
    "DEMOTION-VOLUNTARY","DISCHARGED","DOC TRANSFER","INACTIVE","LAYOFF","LEAVE OF ABSENCE","LEAVE-NON CERTIFIED",
    "MILITARY LEAVE OF ABSENCE","PROBATIONARY DISCHARGE","RESIGNED","RESIGNED-OTHER", 
    "RETIRED","RETIRED-DISABILITY","SUSPENSION","TERMINATED"
  )) %>% 
  group_by(emp_rec_no, agency_name, rank_description) %>% 
  summarize(
    end_date = max(act_date)
  ) %>% 
  ungroup() %>% 
  distinct()

# join history start and end data frames
or_history_df <- or_history_start_df %>% 
  full_join(or_history_end_df, by = c('emp_rec_no','agency_name', 'rank_description')) %>% 
  arrange(emp_rec_no, agency_name, start_date, end_date)

# join history to name index and filter out DPSST USE ONLY which are trainee rows
# export index file to csv
or_index_df <- or_name_index_df %>% 
  left_join(or_history_df, by = c('person_nbr'='emp_rec_no')) %>% 
  filter(! agency_name %in% c("DPSST USE ONLY")) %>%
  rename(c(rank = rank_description)) %>% 
  arrange(person_nbr, agency_name, start_date, end_date) %>% 
  write_csv(paste0(root_dir, output_dir, or_index))


# export out original data files to csv
write_csv(or_employees_df, paste0(root_dir, output_dir, or_original_employees))
write_csv(or_employment_df, paste0(root_dir, output_dir, or_original_employment))
write_csv(or_certifications_df, paste0(root_dir, output_dir, or_original_certifications))
write_csv(or_training_df, paste0(root_dir, output_dir, or_original_training))



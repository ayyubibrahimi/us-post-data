### Processing VT police certification

# check for pacman package, install if not
if(!"pacman" %in% rownames(installed.packages())) {
  install.packages("pacman")
}

# load libraries
pacman::p_load(dplyr, tidyr, readr, lubridate, stringr, janitor, rio, textclean)

# clean working environment
rm(list = ls())

# set directories
root_dir = getwd()
output_dir = "/data/processed/vt/"


# CSV files to import
employees_file = "/data/source/vt/Employees.csv"
employment_file = "/data/source/vt/Employment.csv"
certifications_file = "/data/source/vt/Certifications.csv"

# output CSV files
vt_index = "vt-2023-index.csv"
vt_original_employees = "vt-2023-original-employees.csv"
vt_original_employment = "vt-2023-original-employment.csv"
vt_original_certifications = "vt-2023-original-certifications.csv"

# import data, clean column names, uppercase data, convert dates 
# select is getting rid of any private personal info
# employees_file
vt_employees_df <- read.csv(paste0(root_dir,employees_file)) %>% 
  clean_names() %>% 
  rename(emp_id = employee) %>% 
  unite('full_name', c('first_name',
                       'init',
                       'last_name',
                       'suffix'), sep = " ", remove = FALSE, na.rm = TRUE) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  mutate(across(c(full_name:suffix), ~str_squish(.))) %>% 
  mutate(across(c(full_name:suffix), ~str_replace(.,"\\.", ""))) %>%
  mutate(birth_year = str_split_i(birth_date, "/", 3)) %>% 
  mutate(add_date = paste(str_split_i(add_date, "/", 3),
                          str_pad(str_split_i(add_date, "/", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(add_date, "/",2), 2, side="left", pad="0"), sep = "-")) %>% 
  mutate(chg_date = paste(str_split_i(chg_date, "/", 3),
                          str_pad(str_split_i(chg_date, "/", 1), 2, side="left", pad="0"),
                          str_pad(str_split_i(chg_date, "/",2), 2, side="left", pad="0"), sep = "-")) %>% 
  select(!c(birth_date, ssn, driver_license_no, dl_state, dl_expired, pin_no, file_no, 
            address_line_1, address_line_2, city, state, zip_code, county, 
            county_description, region, region_description, mail_loc, home_phone,
            work_phone, ext, mobile_phone, work_mobile, pager, email,
            user_defined_item_1, user_defined_item_1_description, user_defined_item_2, 
            user_defined_item_2_description, contact_name_1, relat_1, relationship_1_description,
            contact_1_phone, contact_name_2, relat_2, relationship_2_description, 
            contact_2_phone))
  

# employment_file. imported as Latin-1 because of non_ascii 
vt_employment_df <- import(paste0(root_dir,employment_file), encoding = "Latin-1") %>% 
  clean_names() %>% 
  select(-starts_with("V")) %>% 
  mutate(assignment_description = str_replace(assignment_description, "<81>","")) %>% 
  mutate(assignment_description = replace_non_ascii(assignment_description)) %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  arrange(emp_rec_no, agency_name, act_date)

# certifications_file
vt_certifications_df <- import(paste0(root_dir,certifications_file)) %>% 
  clean_names() %>% 
  mutate(across(-emp_rec_no, ~str_to_upper(.))) %>% 
  arrange(emp_rec_no)


# build the index file, starting with employees_file
vt_name_index_df <- vt_employees_df %>% 
  transmute(person_nbr = emp_rec_no,
            full_name,
            last_name,
            first_name,
            middle_name = NA,
            middle_initial = init,
            suffix,
            birth_year,
            age = NA,
            type = type_description) %>% 
  mutate(across(c(birth_year), ~str_replace(.,"NA-0", ""))) %>% 
  distinct() 


# build the work history data with employment_file
# get the actions that would indicate the start date for the agency
# combining the rank and classification because it helps line up start and end dates
vt_history_start_df <- vt_employment_df %>% 
  filter(action_description %in% c("APPOINTED","ELECTED","HIRED","PROMOTION","RANK CHANGE")) %>% 
  group_by(emp_rec_no, agency_name, rank_description, classification_description) %>% 
  summarize(
    start_date = min(act_date)
  ) %>% 
  ungroup() %>% 
  distinct()

# filling down rank and classification because many are missing, then combining like above
# get the actions that indicate the end date for the agency
vt_history_end_df <- vt_employment_df %>% 
  mutate(across(c(rank_description, classification_description), ~na_if(., ""))) %>% 
  group_by(emp_rec_no, agency_name) %>% 
  fill(c(rank_description,classification_description), .direction = "down") %>% 
  ungroup() %>% 
  filter(action_description %in% c("DECEASED","DECERT","DISCHARGED","OTHER SEPARATION - SEE COMMENTS",
                                   "RESIGNED","RETIRED","TERMINATED","TERMINATED (NOT SPECIFIED)")) %>% 
  group_by(emp_rec_no, agency_name, rank_description, classification_description) %>% 
  summarize(
    end_date = max(act_date)
  ) %>% 
  ungroup() %>% 
  distinct()

# join history start and end data frames
vt_history_df <- vt_history_start_df %>% 
  full_join(vt_history_end_df, by = c('emp_rec_no','agency_name', 'rank_description', 'classification_description')) %>% 
  arrange(emp_rec_no, agency_name, start_date, end_date)

# join history to name index and filter out testing applicants
# export index file to csv
vt_index_df <- vt_name_index_df %>% 
  left_join(vt_history_df, by = c('person_nbr'='emp_rec_no'))%>% 
  filter(type != "TESTING APPLICANT") %>% 
  rename(c(rank = rank_description, class = classification_description)) %>% 
  arrange(person_nbr, agency_name, start_date, end_date)%>% 
  write_csv(paste0(root_dir, output_dir, vt_index))

# export out original data files to csv
vt_employees_df %>% 
  select(emp_rec_no:full_name, birth_year, everything()) %>% 
  write_csv(paste0(root_dir, output_dir, vt_original_employees))

write_csv(vt_employment_df, paste0(root_dir, output_dir, vt_original_employment))
write_csv(vt_certifications_df, paste0(root_dir, output_dir, vt_original_certifications))



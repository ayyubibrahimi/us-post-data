### Processing UT police certification

# check for pacman package, install if not
if(!"pacman" %in% rownames(installed.packages())) {
  install.packages("pacman")
}

# load libraries
pacman::p_load(dplyr, tidyr, readr, lubridate, stringr, janitor, readxl)

# clean working environment
rm(list = ls())

# set directories
root_dir = getwd()
output_dir = "/data/processed/ut/"


# CSV files to import
nonslc_file = "/data/source/ut/Report Minus SLCPD 7-2-2024 Final (2).xlsx"
slc_file = "/data/source/ut/Report SLCPD Only 7-2-2024 Final (2).xlsx"

# output CSV files
ut_index = "ut-2024-index.csv"
ut_work_history = "ut-2024-enhanced-work-history.csv"
ut_actions_leo = "ut-2024-enhanced-actions-leo.csv"
ut_original_leo = "ut-2024-original-leo.csv"
ut_original_slc = "ut-2024-original-corrections.csv"


# import data: clean headers, upper, remove whitespace and periods
ut_nonslc_df <- read_excel(paste0(root_dir,nonslc_file), .name_repair = "minimal") %>% 
  clean_names() %>% 
  mutate(across(-person_post_id, ~str_to_upper(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_squish(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_replace(.,"\\.", "")))

ut_slc_df <- read_excel(paste0(root_dir,slc_file), .name_repair = "minimal") %>% 
  clean_names() %>% 
  mutate(across(-person_post_id, ~str_to_upper(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_squish(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_replace(.,"\\.", "")))

# combine nonslc and slc 
ut_leo_df <- bind_rows(ut_nonslc_df, ut_slc_df) %>% 
  distinct()


## create work history and index files
ut_leo_index_df <- ut_leo_df %>%
  select(person_post_id,
         person_last_name,
         person_first_name,
         person_middle_name,
         person_suffix,
         person_gender,
         employing_organization_name,
         employment_appointment_type,
         employment_title_rank_current,
         employment_start_date,
         employment_end_date,
         employment_status,
         employment_change_reason)

# loop through work history (maximum of 13)
for (i in 2:13) {
  ut_leo_history_df <- ut_leo_df %>%
    select(person_post_id,
           employing_organization_name = paste0("employing_organization_name","_",i),
           employment_appointment_type = paste0("employment_appointment_type","_",i),
           employment_title_rank_current = paste0("employment_title_rank_current","_",i),
           employment_start_date = paste0("employment_start_date","_",i),
           employment_end_date = paste0("employment_end_date","_",i),
           employment_status = paste0("employment_status","_",i),
           employment_change_reason = paste0("employment_change_reason","_",i)) %>% 
    filter(!employing_organization_name == '') 
  
  ut_leo_index_df <- bind_rows(ut_leo_index_df, ut_leo_history_df) %>% 
    group_by(person_post_id) %>% 
    fill(person_post_id:person_gender, .direction = "down") %>% 
    ungroup()
}


# clean up & export CSV
ut_leo_index_df <- ut_leo_index_df %>% 
  distinct() %>% 
  unite('full_name', c('person_first_name',
                       'person_middle_name',
                       'person_last_name',
                       'person_suffix'), sep = " ", remove = FALSE, na.rm = TRUE) %>% 
  transmute(person_nbr = person_post_id,
            full_name = str_squish(full_name),
            last_name = person_last_name,
            first_name = person_first_name,
            middle_name = person_middle_name,
            middle_initial = str_sub(person_middle_name,1,1),
            suffix = person_suffix,
            birth_year = NA,
            age = NA,
            agcy_name = employing_organization_name,
            type = employment_appointment_type,
            rank = employment_title_rank_current,
            start_date = employment_start_date,
            end_date = employment_end_date,
            status = employment_status,
            change_reason = employment_change_reason) %>% 
  arrange(person_nbr, start_date, end_date) 

ut_leo_index_df %>% write_csv(paste0(root_dir, output_dir, ut_index), na="")

##############################################################################################
### FIX DATE ISSSUE WHERE SOME START/END DATES ARE COMING IN FROM EXCEL WITHOUT FORMATTING ###
##############################################################################################



### Processing WA police certification

# check for pacman package, install if not
if(!"pacman" %in% rownames(installed.packages())) {
  install.packages("pacman")
}

# load libraries
pacman::p_load(dplyr, tidyr, readr, lubridate, stringr, janitor)

# clean working environment
rm(list = ls())

# set directories
root_dir = getwd()
output_dir = "/data/processed/wa/"


# CSV files to import
leo_file = "/data/source/wa/Ad_Hoc_Export_2022_11_22_03_37_21_PM.csv"
cor_file = "/data/source/wa/Ad_Hoc_Export_2022_11_22_03_46_32_PM.csv"

# output CSV files
wa_index = "wa-2023-index.csv"
wa_work_history = "wa-2023-enhanced-work-history.csv"
wa_actions_leo = "wa-2023-enhanced-actions-leo.csv"
wa_original_leo = "wa-2023-original-leo.csv"
wa_original_cor = "wa-2023-original-corrections.csv"


# import data: clean headers, upper, remove whitespace and periods
wa_leo_df <- read.csv(paste0(root_dir,leo_file)) %>% 
  clean_names() %>% 
  mutate(across(-person_student_id, ~str_to_upper(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_squish(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_replace(.,"\\.", "")))

wa_cor_df <- read.csv(paste0(root_dir,cor_file)) %>% 
  clean_names() %>% 
  mutate(across(-person_student_id, ~str_to_upper(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_squish(.))) %>% 
  mutate(across(c(person_first_name:person_suffix), ~str_replace(.,"\\.", "")))


## create work history and index files
# start with LEO
wa_leo_index_df <- wa_leo_df %>%
  select(person_student_id,
         person_last_name,
         person_first_name,
         person_middle_name,
         person_suffix,
         person_date_of_birth,
         employing_organization_name,
         employment_appointment_type,
         employment_title_rank_current,
         employment_start_date,
         employment_end_date,
         employment_status,
         employment_change_reason)

# loop through work history for LEO (maximum of 10)
for (i in 1:10) {
  wa_leo_history_df <- wa_leo_df %>%
    select(person_student_id,
           employing_organization_name = paste0("employing_organization_name","_",i),
           employment_appointment_type = paste0("employment_appointment_type","_",i),
           employment_title_rank_current = paste0("employment_title_rank_current","_",i),
           employment_start_date = paste0("employment_start_date","_",i),
           employment_end_date = paste0("employment_end_date","_",i),
           employment_status = paste0("employment_status","_",i),
           employment_change_reason = paste0("employment_change_reason","_",i)) %>% 
    filter(!employing_organization_name == '') 
  
  wa_leo_index_df <- bind_rows(wa_leo_index_df, wa_leo_history_df) %>% 
    group_by(person_student_id) %>% 
    fill(person_student_id:person_date_of_birth, .direction = "down") %>% 
    ungroup()
}


# create index file for corrections
wa_cor_index_df <- wa_cor_df %>%
  select(person_student_id,
         person_last_name,
         person_first_name,
         person_middle_name,
         person_suffix,
         person_date_of_birth,
         employing_organization_name,
         employment_appointment_type,
         employment_title_rank_current,
         employment_start_date,
         employment_end_date,
         employment_status,
         employment_change_reason)

# loop through work history for corrections (maximum of 3)
for (i in 1:3) {
  wa_cor_history_df <- wa_cor_df %>%
    select(person_student_id,
           employing_organization_name = paste0("employing_organization_name","_",i),
           employment_appointment_type = paste0("employment_appointment_type","_",i),
           employment_title_rank_current = paste0("employment_title_rank_current","_",i),
           employment_start_date = paste0("employment_start_date","_",i),
           employment_end_date = paste0("employment_end_date","_",i),
           employment_status = paste0("employment_status","_",i),
           employment_change_reason = paste0("employment_change_reason","_",i)) %>% 
    filter(!employing_organization_name == '') 
  
  wa_cor_index_df <- bind_rows(wa_cor_index_df, wa_cor_history_df) %>% 
    group_by(person_student_id) %>% 
    fill(person_student_id:person_date_of_birth, .direction = "down") %>% 
    ungroup() %>% 
    distinct()
}


# combine LEA index with corrections index, clean up & export CSV
wa_work_history_df <- bind_rows(wa_leo_index_df, wa_cor_index_df) %>% 
  distinct() %>% 
  unite('full_name', c('person_first_name',
                       'person_middle_name',
                       'person_last_name',
                       'person_suffix'), sep = " ", remove = FALSE, na.rm = TRUE) %>% 
  transmute(person_nbr = person_student_id,
            full_name = str_squish(full_name),
            last_name = person_last_name,
            first_name = person_first_name,
            middle_name = person_middle_name,
            middle_initial = str_sub(person_middle_name,1,1),
            suffix = person_suffix,
            birth_year = str_split_i(person_date_of_birth, "/", 3),
            age = NA,
            agcy_name = employing_organization_name,
            type = employment_appointment_type,
            rank = employment_title_rank_current,
            start_date = paste(str_split_i(employment_start_date, "/", 3),
                                    str_pad(str_split_i(employment_start_date, "/", 1), 2, side="left", pad="0"),
                                    str_pad(str_split_i(employment_start_date, "/",2), 2, side="left", pad="0"), sep = "-"),
            end_date = paste(str_split_i(employment_end_date, "/", 3),
                                str_pad(str_split_i(employment_end_date, "/", 1), 2, side="left", pad="0"),
                                str_pad(str_split_i(employment_end_date, "/",2), 2, side="left", pad="0"), sep = "-"),
            status = employment_status,
            change_reason = employment_change_reason) %>% 
  mutate(across(c(start_date,end_date), na_if, "NA-00-NA")) %>%
  arrange(person_nbr, start_date, end_date) %>% 
  write_csv(paste0(root_dir, output_dir, wa_work_history))

# export index file (w/ status and change_reason removed)
wa_work_history_df %>% 
  select(!c(status, change_reason)) %>% 
  distinct() %>% 
  write_csv(paste0(root_dir, output_dir, wa_index))



## create actions file (for LEO only)
# select first action listed
wa_leo_actions_df <- wa_leo_df %>%
  select(person_nbr = person_student_id,
         action,
         status = status_1,
         effective_date)

# loop through to get action history (maximum of 5)
for (i in 1:5) {
  wa_leo_action_history_df <- wa_leo_df %>%
    select(person_nbr = person_student_id,
           action = paste0("action","_",i),
           status = paste0("status","_",i+1),
           effective_date = paste0("effective_date","_",i)) %>% 
    filter(!action == '') 
  
  wa_leo_actions_df <- bind_rows(wa_leo_actions_df, wa_leo_action_history_df) 
}

# join back to index file to get name
wa_leo_actions_df %>% left_join(
  wa_work_history_df %>% distinct(person_nbr, full_name, birth_year),
  by = c('person_nbr'='person_nbr')) %>% 
  select(person_nbr, full_name, birth_year, everything()) %>% 
  mutate(effective_date = paste(str_sub(effective_date,7,10), 
                   str_sub(effective_date,1,2), 
                   str_sub(effective_date,4,5), sep = "-")) %>% 
  arrange(person_nbr, effective_date) %>% 
  distinct() %>% 
  write_csv(paste0(root_dir, output_dir, wa_actions_leo))



## export out original data as CSV without birthdate
wa_leo_df %>% 
  mutate(birth_year = str_sub(person_date_of_birth,7,10)) %>% 
  select(person_student_id:person_suffix, birth_year, everything(), -person_date_of_birth) %>%
  write_csv(paste0(root_dir, output_dir, wa_original_leo))

wa_cor_df %>% 
  mutate(birth_year = str_sub(person_date_of_birth,7,10)) %>% 
  select(person_student_id:person_suffix, birth_year, everything(), -person_date_of_birth) %>%
  write_csv(paste0(root_dir, output_dir, wa_original_cor))






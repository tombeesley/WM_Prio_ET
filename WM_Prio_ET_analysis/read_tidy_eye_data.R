library(tidyverse)
library(eyetools)

# this bit reads in the files and uses part of the filename to make a new "subj" variable
fnams <- list.files("Eye_raw_data", "Study1_ET", full.names = TRUE) # needed for reading data
subjs <- list.files("Eye_raw_data", "Study1_ET") # needed for identifying subject numbers
data <- NULL
for (subj in 1:length(fnams)) {
  print(subj)
  pData <- read_csv(fnams[subj], col_types = cols(), col_names = TRUE) # read the data from csv
  pData <- pData %>%
    mutate(id = gsub("^(([^_]*_){7}[^_]*).*", "\\1", subjs[[subj]]), # get everything up to 7th underscore
           id = substr(id, 18, nchar(id))) %>% # get rid of study name
    select(id,everything())
  
  # select columns
  print("select columns")
  pData <- 
    pData %>% 
    select(id,
           device_time_stamp, 
           system_time_stamp,
           left_gaze = left_gaze_point_on_display_area,
           left_validity = left_gaze_point_validity,
           right_gaze = right_gaze_point_on_display_area,
           right_validity = right_gaze_point_validity,
           trial,
           trial_phase,
           pp_TS)
  
  # process the left and right eye data columns into separate x and y variables
  print("split eye variables")
  pData <- 
    pData %>% 
    mutate(left_gaze = gsub("[()]", "", left_gaze), # remove parentheses from numbers
           right_gaze = gsub("[()]", "", right_gaze)) %>% 
    separate(left_gaze, into = c("left_x", "left_y"), sep = ",") %>% 
    separate(right_gaze, into = c("right_x", "right_y"), sep = ",") %>% 
    mutate(across(left_x:right_y,as.numeric))
  
  # get both eyes
  print("recode as NA")
  pData <- 
    pData %>% 
    mutate(left_x = case_when(left_validity == 1 ~ left_x,
                              left_validity == 0 ~ NA_real_), # change NaN to NA values
           left_y = case_when(left_validity == 1 ~ left_y,
                              left_validity == 0 ~ NA_real_),
           right_x = case_when(right_validity == 1 ~ right_x,
                               right_validity == 0 ~ NA_real_), # change NaN to NA values
           right_y = case_when(right_validity == 1 ~ right_y,
                               right_validity == 0 ~ NA_real_)) %>% 
    select(id, device_time_stamp, left_x, left_y, right_x, right_y, trial, trial_phase)
  
  print("add to data")
  data <- rbind(data, pData) # combine data array with existing data

}

data <- 
  data %>% 
  group_by(id) %>% 
  mutate(time = round((device_time_stamp - device_time_stamp[1])/1000)) %>% # set first timestamp to 0 and all others corrected afterwards)
  select(-device_time_stamp, id, time, everything())

saveRDS(data, "data_22_08_22.RDS")



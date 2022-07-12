library(tidyverse)
library(eyetools)

# this bit reads in the files and uses part of the filename to make a new "subj" variable
fnams <- list.files("Eye_raw_data", "Study1_ET", full.names = TRUE) # needed for reading data
subjs <- list.files("Eye_raw_data", "Study1_ET") # needed for identifying subject numbers
data <- NULL
for (subj in 1:length(fnams)) {
  pData <- read_csv(fnams[subj], col_types = cols(), col_names = TRUE) # read the data from csv
  pData <- pData %>%
    mutate(subj = substr(subjs[subj],1,str_length(subjs[subj])-7)) %>%
    select(subj,everything())
  data <- rbind(data, pData) # combine data array with existing data
}



# select the columns we need from the eye data, rename them
d <- 
  d_raw %>% 
  select(device_time_stamp, 
         system_time_stamp,
         left_gaze = left_gaze_point_on_display_area,
         left_validity = left_gaze_point_validity,
         right_gaze = right_gaze_point_on_display_area,
         right_validity = right_gaze_point_validity,
         trial,
         trial_phase,
         pp_TS)

# process the left and right eye data columns into separate x and y variables
d <- 
  d %>% 
  mutate(left_gaze = gsub("[()]", "", left_gaze), # remove parentheses from numbers
         right_gaze = gsub("[()]", "", right_gaze)) %>% 
  separate(left_gaze, into = c("left_x", "left_y"), sep = ",") %>% 
  separate(right_gaze, into = c("right_x", "right_y"), sep = ",") %>% 
  mutate(across(where(is.character),as.numeric))


# get both eyes
d <- 
  d %>% 
  mutate(time = round((device_time_stamp - device_time_stamp[1])/1000)) %>% # set first timestamp to 0 and all others corrected afterwards
  select(-device_time_stamp, -system_time_stamp)  %>% 
  mutate(left_x = case_when(left_validity == 1 ~ left_x,
                            left_validity == 0 ~ NA_real_), # change NaN to NA values
         left_y = case_when(left_validity == 1 ~ left_y,
                            left_validity == 0 ~ NA_real_),
         right_x = case_when(right_validity == 1 ~ right_x,
                             right_validity == 0 ~ NA_real_), # change NaN to NA values
         right_y = case_when(right_validity == 1 ~ right_y,
                             right_validity == 0 ~ NA_real_)) %>% 
  select(time, left_x, left_y, right_x, right_y, trial, trial_phase)

# split the file
d_spaced_3s <- 
  d %>% 
  filter(time < 2000000)

d_spaced_2s <- 
  d %>% 
  filter(time > 2000000)

save(d_spaced_2s, d_spaced_3s, file = "data_pilot.RData")

#saveRDS(d, "data_pilot.RDS")

  



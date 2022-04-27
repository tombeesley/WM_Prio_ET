library(tidyverse)
library(eyetools)

# pilot data of 20 trials
d_raw <- read_csv("Raw_data/ET_csv_5224.csv")

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


# left eye is better - take that for now
d <- 
  d %>% 
  mutate(time = round((device_time_stamp - device_time_stamp[1])/1000)) %>% # set first timestamp to 0 and all others corrected afterwards
  select(time,
         x = left_x, 
         y = left_y, 
         validity = left_validity,
         trial,
         trial_phase)  %>% 
  mutate(x = case_when(validity == 1 ~ x,
                       validity == 0 ~ NA_real_), # change NaN to NA values
         y = case_when(validity == 1 ~ y,
                       validity == 0 ~ NA_real_)) %>% 
  select(-validity) # no longer need validity

saveRDS(d, "data_pilot.RDS")

  



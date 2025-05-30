library(tidyverse)
library(eyetools)

rm(list=ls())

saveOne = TRUE

rfs_path <- "//luna.lancs.ac.uk/FST/PS/Users/beesleyt/WM_Prio_ET/Raw Data"

# check that the rfs_path is returning / is connected
if (length(list.files(rfs_path)) == 0) {
  stop("Research filestore is possibly not connected")
} else { # continue to process the files
  # this bit reads in the files and uses part of the filename to make a new "subj" variable
  fnams <- list.files(rfs_path, "Study1_ET", full.names = TRUE) # needed for reading data
  subjs <- list.files(rfs_path, "Study1_ET") # needed for identifying subject numbers
  
  data_fix <- NULL
  data_missing <- NULL
  
  
  for (subj in 1:length(fnams)) {
    
    print(c("reading file:", fnams[subj]))
    pData <- read_csv(fnams[subj], col_types = cols(), col_names = TRUE) # read the data from csv
    pData <- pData %>%
      mutate(id = substr(subjs[subj],18,32)) %>%
      select(id,everything())
    
    # get participant number
    pNum <- pull(pData[1,'id'])
    print(pNum)
    
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
    
    
    
    # set first timestamp to 0 and all others corrected afterwards)
    print("adjust timestamps")
    print(colnames(pData))
    pData <- 
      pData %>% 
      group_by(id) %>% 
      mutate(time = round((device_time_stamp - device_time_stamp[1])/1000))
    
    for (p in c(5,7,8)) {
      
      print(p)
      
      pdata_period <- 
        pData %>% 
        filter(trial_phase == p) %>% # filter to relevant part of the trial
        select(-device_time_stamp, -trial_phase, id, time, everything())
      
      
      # combine eye data to single x/y
      pdata_period <- combine_eyes(pdata_period, "average")
      
      # change to screen coordinates
      pdata_period <- 
        pdata_period %>% 
        mutate(x = x*1920, y = y*1080)

      # interpolation
      pdata_period <- interpolate(pdata_period)
      
      # calculate prop of data missing for each trial
      pData_missing <- 
        pdata_period %>% 
        group_by(trial) %>% 
        summarise(prop_na = mean(is.na(x)))
      
      # process fixations
      print("process fixations")
      p_fix <- fix_dispersion(pdata_period, disp_tol = 75, run_interp = FALSE)
      
      # add id and period column and combine with other data
      print("add to data")
      p_fix <- p_fix %>% mutate(id = pNum, .before = trial) %>% mutate(trial_period = p)
      pData_missing <- pData_missing %>% mutate(id = pNum, .before = trial) %>% mutate(trial_period = p)
      
      data_fix <- rbind(data_fix, p_fix) # combine data array with existing data
      data_missing <- rbind(data_missing, pData_missing) # combine data_missing array with existing data
    }
    
    
    
  } # data processing steps
  
  save_path <- paste0("proc_data_",Sys.Date(),".RData")
  save(data_fix,data_missing, file = save_path)
  
  
}



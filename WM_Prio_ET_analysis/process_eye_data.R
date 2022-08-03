library(tidyverse)
library(eyetools) # github.com/tombeesley/eyetools
library(patchwork)

theme_set(theme_light())

d_raw <- readRDS("data_12_07_22.RDS")

# combine eyes separately for each participant
d <- NULL
idVals <- distinct(d_raw,id)
for (s in 1:nrow(idVals)) {
  print(s)
  d_temp <- filter(d_raw, id == idVals[s,])
  d_temp <- combine_eyes(d_temp, "average")
  d_temp$id <- pull(idVals[s,])
  d <- rbind(d, d_temp)
}

# change to screen coordinates
d <- 
  d %>% 
  mutate(x = x*1920, y = y*1080)

# filter to relevant part of the trial
d_s <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase)

d_s <- d_s[1:100000,]

d_s$id <-  1

# process fixations (has issues with s = 2,5,6 - need to fix)
df <-  NULL
idVals <- distinct(d_s,id)
for (s in 1:nrow(idVals)){
  print(s)
  d_temp <- filter(d_s, id == idVals[s,])
  d_temp <- fix_dispersion(d_temp, disp_tol = 75)
  d_temp$id <- idVals[s,]
  df <- rbind(df, d_temp)
}



# compute data in areas of interest

# d_sample <- 
#   df %>% 
#   filter(id == 5)

AOIs <- data.frame(x = c(660,660, 1260, 1260),
                   y = c(840,240, 840, 240), 
                   width = c(400,400,400,400),
                   height = c(400,400,400,400))

# #plot the fixations and raw data
# spatial_plot(fix_data = d_sample,
#              AOIs = AOIs,
#              res = c(0,1920,0,1080), 
#              show_fix_order = TRUE)

# areas of interest capture groupings of fixations
d_aoi <-  NULL
idVals <- distinct(df,id)
for (s in 1:nrow(idVals)){
  print(s)
  d_temp <- filter(df, id == idVals[s,])
  d_temp <- AOI_time(d_temp, 
                     AOIs = AOIs,
                     c("bottom_left", "top_left", "bottom_right", "top_right"))
  d_temp$id <- idVals[s,]
  d_aoi <- rbind(d_aoi, d_temp)
}

count(d_aoi,id)

d_aoi <- d_aoi %>% filter(id != "Pri_ET_Study1_7")

d_aoi <- d_aoi %>% mutate(id = as.character(id),
                          across(trial:top_right, as.numeric))

d_beh <- read_csv("behavioural_data_14_07.csv")

d_beh <- 
  d_beh %>% mutate(trial = n_trial, .keep = "unused", .after = "id")

d_all <- left_join(d_beh, d_aoi, by = c("id", "trial"))

# analyse eye data on position

d_selected <- 
  d_all %>% 
  select(id,trial, prioritised, high_value_SL, tested_SL, bottom_left:top_right)

d_selected %>% 
  group_by(high_value_SL) %>% 
  summarise(across(bottom_left:top_right, ~ mean(., na.rm = TRUE)))



## Exploratory analysis of pilot data


# how many fixations per trial
fix_summary <- 
  f_disp %>% 
  group_by(trial) %>% 
  summarise(nFix = n(),
            meanDur = mean(duration))

# distribution of fixation counts
nFixplot <- 
  fix_summary %>% 
  ggplot() +
  geom_histogram(aes(nFix))

# distribution of fixation durations
meanDurPlot <- 
  fix_summary %>% 
  ggplot() +
  geom_histogram(aes(meanDur))

nFixplot + meanDurPlot


f_sac <-
  eyetools::VTI_saccade(d_s)


AOIs <- data.frame(x = c(540,540, 1380, 1380),
                   y = c(960,120, 960, 120), 
                   width = c(60,60,60,60),
                   height = c(60,60,60,60))

#plot the fixations and raw data
spatial_plot(raw_data = d_s, 
             fix_data = f_disp,
             sac_data = f_sac,
             AOIs = AOIs,
             res = c(0,1920,0,1080), 
             show_fix_order = TRUE)

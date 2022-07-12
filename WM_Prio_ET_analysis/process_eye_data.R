library(tidyverse)
library(eyetools) # github.com/tombeesley/eyetools
library(patchwork)

theme_set(theme_light())

#d_raw <- readRDS("data_pilot.RDS")
load("data_pilot.RData")

d_raw <- combine_eyes(d_spaced_2s,"average")

# change to screen coordinates
d <- 
  d_raw %>% 
  mutate(x = x*1920, y = y*1080)

d_s <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase) %>% 
  filter(between(trial, 34, 34))

# process fixations
f_disp <- 
  eyetools::fix_dispersion(d_s, disp_tol = 75)


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

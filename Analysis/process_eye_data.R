library(tidyverse)
library(eyetools) # github.com/tombeesley/eyetools
library(patchwork)

theme_set(theme_light())

d_raw <- readRDS("data_pilot.RDS")

d_raw <- combine_eyes(d_raw,"average")

# change to screen coordinates
d <- 
  d_raw %>% 
  mutate(x = x*1920, y = y*1080)

d_s <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase) %>% 
  filter(between(trial, 1, 140))

# process fixations
f_disp <- 
  eyetools::fix_dispersion(d_s, disp_tol = 75)


# how many fixations per trial
fix_summary <- 
  f_disp %>% 
  group_by(trial) %>% 
  summarise(nFix = n(),
            meanDur = mean(dur))

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


# f_vel <- 
#   eyetools::VTI_saccade(d_s)


AOIs <- data.frame(x = c(840,840, 1080, 1080),
                   y = c(660,420, 660, 420), 
                   width = c(50,50,50,50),
                   height = c(50,50,50,50))

#plot the fixations and raw data
spatial_plot(raw_data = d_s, 
             fix_data = f_disp,
             AOIs = AOIs,
             res = c(400,1520,200,880), 
             show_fix_order = TRUE)

library(tidyverse)
library(eyetools)

d <- readRDS("data_pilot.RDS")

d <- 
  d %>% 
  mutate(x = x*1920, y = y*1080) 

d7 <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase) %>% 
  filter(trial == 18)

fix7 <- 
  eyetools::fix_dispersion(d7)

spatial_plot(raw_data = d7, 
             fix_data = fix7, 
             res = c(0,1920,0,1080), 
             show_fix_order = FALSE)

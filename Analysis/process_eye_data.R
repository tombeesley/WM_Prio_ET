library(tidyverse)
library(eyetools) # github.com/tombeesley/eyetools

d <- readRDS("data_pilot.RDS")

# change to screen coordinates
d <- 
  d %>% 
  mutate(x = x*1920, y = y*1080) 

d7 <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase) %>% # eyetools does not recognise this column.
  filter(trial == 18)

# process fixations
fix7 <- 
  eyetools::fix_dispersion(d7)

#plot the fixations and raw data
spatial_plot(raw_data = d7, 
             fix_data = fix7, 
             res = c(0,1920,0,1080), 
             show_fix_order = FALSE)

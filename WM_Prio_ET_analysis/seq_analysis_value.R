library(eyetools)
library(tidyverse)

d <- read_csv("Exp2_AOI_seq_data_for_Tom.csv")

d %>% 
  filter(entry_n <= 4) %>% 
  group_by(id, trial, entry_n) %>% 
  summarise()

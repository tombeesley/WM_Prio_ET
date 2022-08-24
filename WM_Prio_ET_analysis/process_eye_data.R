library(tidyverse)
library(eyetools) # github.com/tombeesley/eyetools
library(patchwork)

theme_set(theme_light())

d_raw <- readRDS("data_22_08_22.RDS")

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

# ENCODING PROCESSING

# filter to relevant part of the trial
d_s <- 
  d %>% 
  filter(trial_phase == 7) %>% 
  select(-trial_phase)

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

d_aoi <- d_aoi %>% mutate(id = as.character(id),
                          across(trial:top_right, as.numeric))

d_beh <- read_csv("behavioural_data_22_08.csv")

d_beh <- 
  d_beh %>% mutate(trial = n_trial, .keep = "unused", .after = "id")

d_all <- left_join(d_beh, d_aoi, by = c("id", "trial"))

# analyse eye data on position

# # creates a new column called missing. This is equal to 1 if any of the AoI are missing and 0 if all present
# 
# d_selected <- d_all %>% 
#   select(id,trial, prioritised, high_value_SL, tested_SL, bottom_left:top_right) %>%
#   mutate(missing = case_when((is.na(bottom_left)) | (is.na(top_left)) | (is.na(bottom_right)) | (is.na(top_right)) ~ 1,
#          TRUE ~ 0))
# 
# # frequency of missing cells per participant
# 
# table(d_selected$missing, d_selected$id)
# 
# # look at number of trials with no data per participant
# 
# missing_data_at_trial_level <- d_selected %>% 
#   group_by(id) %>%
#   filter(missing == 1) %>%
#   summarise(n = n())
# 
# missing_data_at_trial_level_stats <- missing_data_at_trial_level %>% 
#   summarise(mean_missing = mean(n),
#             sd_missing = sd(n))
# 
# cut_off <- missing_data_at_trial_level_stats$mean_missing + (2*missing_data_at_trial_level_stats$sd_missing)
# cut_off

d_selected <- d_all %>% selec(id, trial, prioritised, high_value_SL, tested_SL, bottom_left:top_right)


# divides by total encoding time. This gives a value equal to the proportion of time participants spend fiating at an AoI / total encoding time
d_selected <- d_selected %>% # divides by total encoding time
  rowwise() %>% 
  mutate(bottom_left_prop = bottom_left /2000,
         top_left_prop = top_left / 2000,
         bottom_right_prop = bottom_right / 2000, 
         top_right_prop = top_right / 2000)

# makes the three types of value cells: high, equal and low value

d_selected <- d_selected %>%
  rowwise() %>%
  mutate(high_value_eye_prop = case_when(high_value_SL=="BL" ~ bottom_left_prop, # when BL is high value item, make high value prop = bottom left prop
                                    high_value_SL=="TL" ~ top_left_prop,
                                    high_value_SL=="BR" ~ bottom_right_prop, 
                                    high_value_SL=="TR" ~ top_right_prop,
                                    TRUE ~ NA_real_),
         low_value_eye_prop = case_when(high_value_SL=="BL" ~ mean(c(top_left_prop, bottom_right_prop, top_right_prop)), # when BL is high value item, make low value prop = average of other three items
                                   high_value_SL=="TL" ~ mean(c(bottom_left_prop, bottom_right_prop, top_right_prop)), 
                                   high_value_SL=="BR" ~ mean(c(bottom_left_prop, top_left_prop, top_right_prop)), 
                                   high_value_SL=="TR" ~ mean(c(bottom_left_prop, top_left_prop, bottom_right_prop)), 
                                   TRUE ~ NA_real_),
         equal_value_eye_prop = case_when(prioritised=="equal value" ~ mean(c(bottom_left_prop, top_left_prop, bottom_right_prop, top_right_prop)), # equal = average spent time fixating at the four AoI
                                     TRUE ~ NA_real_))

# summarise across trials by participant                                   
eye_data <- d_selected %>% 
  group_by(id) %>% 
  summarise(high_value = mean(high_value_eye_prop, na.rm = TRUE),
            low_value = mean(low_value_eye_prop, na.rm = TRUE),
            equal_value = mean(equal_value_eye_prop, na.rm = TRUE))

# convert data into tidy format
eye_data_tidy <- gather(eye_data, value, fixation_time, high_value:equal_value, factor_key=TRUE)

# summarise
eye_data_summary <- eye_data_tidy %>%
  group_by(value) %>%
  summarise(mean_fixation_time = mean(fixation_time),
            sd = sd(fixation_time),
            n = n(),
            se = sd/sqrt(n))


#--------------------------
# Plot
#-------------------------

# Overall plot

eye_data_summary$value <- recode(eye_data_summary$value, "high_value" = "High",
                                 "equal_value" = "Equal",
                                 "low_value" = "Low")

eye_data_summary$value <- factor(eye_data_summary$value, c("High", "Equal", "Low"))

basic_eye_data_plot <- ggplot(data = eye_data_summary,
                                      mapping = aes(x = value, y = mean_fixation_time,
                                                    shape = value, group = value, color = value)) + 
  geom_point(position = position_dodge(width = 0.5), size = 3)+
  geom_errorbar(width = c(0.2), position = position_dodge(width = 0.5), size = 1,
                aes(ymax = mean_fixation_time + se,
                    ymin = mean_fixation_time - se)) +
  labs(x = "Value", y = "Proportion of encoding time") +
  ylim(c(0,0.4))+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        strip.background = element_blank(),
        legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 14))

basic_eye_data_plot

ggsave(paste0("Figures/basic_eye_data_plot-", format(Sys.Date(), ("%d-%m-%y")), ".png"), height = 4, width = 4, dpi = 800, bg = "white")



## Exploratory analysis of pilot data


# how many fixations per trial

# RETENTION PROCESSING

# filter to relevant part of the trial
d_retention <- 
  d %>% 
  filter(trial_phase == 8) %>% 
  select(-trial_phase)

# process fixations during maintenance
df_retention <-  NULL
idVals <- distinct(d_retention,id)
for (s in 1:nrow(idVals)){
  print(s)
  d_temp <- filter(d_retention, id == idVals[s,])
  d_temp <- fix_dispersion(d_temp, disp_tol = 75)
  d_temp$id <- idVals[s,]
  df_retention <- rbind(df_retention, d_temp)
}

# compute data in areas of interest

AOIs <- data.frame(x = c(660,660, 1260, 1260),
                   y = c(840,240, 840, 240), 
                   width = c(400,400,400,400),
                   height = c(400,400,400,400))

# areas of interest capture groupings of fixations
d_aoi_retention <-  NULL
idVals <- distinct(df_retention,id)
for (s in 1:nrow(idVals)){
  print(s)
  d_temp <- filter(df_retention, id == idVals[s,])
  d_temp <- AOI_time(d_temp, 
                     AOIs = AOIs,
                     c("bottom_left", "top_left", "bottom_right", "top_right"))
  d_temp$id <- idVals[s,]
  d_aoi_retention <- rbind(d_aoi_retention, d_temp)
}

count(d_aoi_retention,id)

d_aoi_retention <- d_aoi_retention %>% mutate(id = as.character(id),
                          across(trial:top_right, as.numeric))

d_beh <- read_csv("behavioural_data_22_08.csv")

d_beh <- 
  d_beh %>% mutate(trial = n_trial, .keep = "unused", .after = "id")

d_all_retention <- left_join(d_beh, d_aoi_retention, by = c("id", "trial"))

# divides by total retention time. This gives a value equal to the proportion of time participants spend fiating at an AoI / total retention time

d_selected_retention <- d_all_retention %>% select(id, trial, prioritised, high_value_SL, tested_SL, bottom_left:top_right)

d_selected_retention <- d_selected_retention %>% # divides by total encoding time
  rowwise() %>% 
  mutate(bottom_left_prop = bottom_left /1600,
         top_left_prop = top_left / 1600,
         bottom_right_prop = bottom_right / 1600, 
         top_right_prop = top_right / 1600)

# makes the three types of value cells: high, equal and low value

d_selected_retention <- d_selected_retention %>%
  rowwise() %>%
  mutate(high_value_eye_prop = case_when(high_value_SL=="BL" ~ bottom_left_prop, # when BL is high value item, make high value prop = bottom left prop
                                         high_value_SL=="TL" ~ top_left_prop,
                                         high_value_SL=="BR" ~ bottom_right_prop, 
                                         high_value_SL=="TR" ~ top_right_prop,
                                         TRUE ~ NA_real_),
         low_value_eye_prop = case_when(high_value_SL=="BL" ~ mean(c(top_left_prop, bottom_right_prop, top_right_prop)), # when BL is high value item, make low value prop = average of other three items
                                        high_value_SL=="TL" ~ mean(c(bottom_left_prop, bottom_right_prop, top_right_prop)), 
                                        high_value_SL=="BR" ~ mean(c(bottom_left_prop, top_left_prop, top_right_prop)), 
                                        high_value_SL=="TR" ~ mean(c(bottom_left_prop, top_left_prop, bottom_right_prop)), 
                                        TRUE ~ NA_real_),
         equal_value_eye_prop = case_when(prioritised=="equal value" ~ mean(c(bottom_left_prop, top_left_prop, bottom_right_prop, top_right_prop)), # equal = average spent time fixating at the four AoI
                                          TRUE ~ NA_real_))

# summarise across trials by participant                                   
eye_data_retention <- d_selected_retention %>% 
  group_by(id) %>% 
  summarise(high_value = mean(high_value_eye_prop, na.rm = TRUE),
            low_value = mean(low_value_eye_prop, na.rm = TRUE),
            equal_value = mean(equal_value_eye_prop, na.rm = TRUE))

# convert data into tidy format
eye_data_tidy_retention <- gather(eye_data_retention, value, fixation_time, high_value:equal_value, factor_key=TRUE)

# summarise
eye_data_summary_retention <- eye_data_tidy_retention %>%
  group_by(value) %>%
  summarise(mean_fixation_time = mean(fixation_time),
            sd = sd(fixation_time),
            n = n(),
            se = sd/sqrt(n))


#--------------------------
# Plot
#-------------------------

# Overall plot

eye_data_summary_retention$value <- recode(eye_data_summary_retention$value, "high_value" = "High",
                                 "equal_value" = "Equal",
                                 "low_value" = "Low")

eye_data_summary_retention$value <- factor(eye_data_summary_retention$value, c("High", "Equal", "Low"))

basic_eye_data_plot_retention <- ggplot(data = eye_data_summary_retention,
                              mapping = aes(x = value, y = mean_fixation_time,
                                            shape = value, group = value, color = value)) + 
  geom_point(position = position_dodge(width = 0.5), size = 3)+
  geom_errorbar(width = c(0.2), position = position_dodge(width = 0.5), size = 1,
                aes(ymax = mean_fixation_time + se,
                    ymin = mean_fixation_time - se)) +
  labs(x = "Value", y = "Proportion of retention time") +
  ylim(c(0,0.4))+
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        strip.background = element_blank(),
        legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 14))

basic_eye_data_plot_retention

ggsave(paste0("Figures/basic_eye_data_plot-RETENTION-", format(Sys.Date(), ("%d-%m-%y")), ".png"), height = 4, width = 4, dpi = 800, bg = "white")



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

###-------------------------------------------- ###
###  Load in libraries  ###
### ------------------------------------------- ###

library(tidyverse)
library(cowplot)
library(BayesFactor)
library(afex)
library(emmeans)

###-------------------------------------------- ###
###  Read in the data  ###
### ------------------------------------------- ###

files_list <- paste("Behavioural_data/", list.files("Behavioural_data/"), sep = "")

behavioural_data <- map_df(files_list, read_csv) %>%
  select(-(c(dob, date, correct_response, response, gender)))

# filter so we only have the test trials (i.e. remove practice trials)

behavioural_data <- behavioural_data %>% filter(test_stage == "test")

# Compute recall error 

behavioural_data$response_angle <- as.numeric(behavioural_data$response_angle)
behavioural_data$correct_response_angle <- as.numeric(behavioural_data$correct_response_angle)

behavioural_data$deviation <- behavioural_data$response_angle-behavioural_data$correct_response_angle
behavioural_data$deviation[which(behavioural_data$deviation > 180)] <- behavioural_data$deviation[which(behavioural_data$deviation > 180)] -360
behavioural_data$deviation[which(behavioural_data$deviation <= -180)] <- behavioural_data$deviation[which(behavioural_data$deviation <= -180)] +360

behavioural_data$recallError <- abs(behavioural_data$deviation)

###------------------------ ###
###    Define conditions    ###
### ------------------------ ###

# define as low value, unless otherwise specified below

behavioural_data$prioritised <- "low value"

# If it is a prioritised condition and the more valuable item is tested, rename as high value
# Note python iterates from 0, so in the tested_position, the value is equal to value-1

behavioural_data[behavioural_data$condition == "Prioritise1" & behavioural_data$tested_position == "0", "prioritised"] <- "high value"
behavioural_data[behavioural_data$condition == "Prioritise2" & behavioural_data$tested_position == "1", "prioritised"] <- "high value"
behavioural_data[behavioural_data$condition == "Prioritise3" & behavioural_data$tested_position == "2", "prioritised"] <- "high value"
behavioural_data[behavioural_data$condition == "Prioritise4" & behavioural_data$tested_position == "3", "prioritised"] <- "high value"

# Define prioritised as equal value if the condition is "NoPrioritise" 

behavioural_data[behavioural_data$condition == "NoPrioritise", "prioritised"] <- "equal value"

# Define high value and tested spatial locations

behavioural_data$high_value_SL <- NA

behavioural_data[behavioural_data$condition == "Prioritise1", "high_value_SL"] <- "TL"
behavioural_data[behavioural_data$condition == "Prioritise2", "high_value_SL"] <- "TR"
behavioural_data[behavioural_data$condition == "Prioritise3", "high_value_SL"] <- "BL"
behavioural_data[behavioural_data$condition == "Prioritise4", "high_value_SL"] <- "BR"
behavioural_data[behavioural_data$condition == "NoPrioritise", "high_value_SL"] <- "None"

behavioural_data$tested_SL <- NA

behavioural_data[behavioural_data$tested_position == "0", "tested_SL"] <- "TL"
behavioural_data[behavioural_data$tested_position == "1", "tested_SL"] <- "TR"
behavioural_data[behavioural_data$tested_position == "2", "tested_SL"] <- "BL"
behavioural_data[behavioural_data$tested_position == "3", "tested_SL"] <- "BR"


###------------------------ ###
###    Create dataframes    ###
### ------------------------ ###

# summarise the data by id and prioritised. Calculate mean recall error

behavioural_data_tidy <- behavioural_data %>%
  group_by(id, prioritised) %>%
  summarise(m_recall_error = mean(recallError))

# Rename the variables for the figures

behavioural_data_tidy$prioritised <- recode(behavioural_data_tidy$prioritised, "equal value" = "Equal", "high value" = "High", "low value" = "Low")

# Make the data wide 
behavioural_data_wide <- behavioural_data_tidy %>%
  ungroup() %>%
  mutate(cell = paste(prioritised)) %>%
  select(-c(prioritised)) %>%
  spread(cell, m_recall_error)

# Create summary table - this contains the means across pps

behavioural_data_summary <- behavioural_data_tidy %>%
  group_by(prioritised) %>%
  summarise(mean_recall_error = mean(m_recall_error),
            sd = sd(m_recall_error),
            n = n(),
            se = sd/sqrt(n))

#--------------------------
# Plot
#-------------------------

# Overall plot

behavioural_data_summary$prioritised <- factor(behavioural_data_summary$prioritised, c("High", "Equal", "Low"))

basic_behavioural_data_plot <- ggplot(data = behavioural_data_summary,
                           mapping = aes(x = prioritised, y = mean_recall_error,
                                         shape = prioritised, group = prioritised, color = prioritised)) + 
  geom_point(position = position_dodge(width = 0.5), size = 2)+
  geom_errorbar(width = c(0.2), position = position_dodge(width = 0.5), size = 1,
                aes(ymax = mean_recall_error + se,
                    ymin = mean_recall_error - se)) +
  labs(x = "Value", y = "Recall error (°)") +
  scale_y_continuous(limits = c(0, 90)) +
  theme(axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        strip.background = element_blank(),
        legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 14))

basic_behavioural_data_plot

ggsave(paste0("Figures/basic_behavioural_data_plot-", format(Sys.Date(), ("%d-%m-%y")), ".png"), height = 4, width = 4, dpi = 800, bg = "white")

write_csv(behavioural_data, "behavioural_data_24_10.csv")

# Frequentist analysis ----

main_anova <- aov_4(recallError ~ prioritised + (prioritised|id), data = behavioural_data_tidy)
main_anova

pairwise_prioritised <- emmeans(main_anova, ~prioritised)
pairwise_prioritised

pairwise_prioritised_outcomes <- as.data.frame(pairs(pairwise_prioritised)) %>%
  mutate(p_corrected = p.adjust(p.value, method="holm"))

pairwise_prioritised_outcomes

# Bayes Factor analysis ----

set.seed(100) 
iter = 500000
behavioural_data_tidy$id <- as.factor(behavioural_data_tidy$id)
behavioural_data_tidy$prioritised <- as.factor(behavioural_data_tidy$prioritised)

main_anova_bf <- anovaBF(formula = m_recall_error ~ prioritised + id, data = behavioural_data_tidy, whichModels = "all", whichRandom = "id", iterations = iter)
main_anova_bf

# follow up t-tests

bf_high_low  <- ttestBF(x = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "High"], 
                        y = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "Low"],
                        paired=TRUE)

bf_high_equal  <- ttestBF(x = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "High"], 
                          y = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "Equal"],
                          paired=TRUE)

bf_low_equal  <- ttestBF(x = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "Equal"], 
                         y = behavioural_data_tidy$m_recall_error[behavioural_data_tidy$prioritised == "Low"],
                         paired=TRUE)



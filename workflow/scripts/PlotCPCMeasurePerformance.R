#
# PlotDistanceMetricPerformance.R
#
# author: Dakota Murray
#
# Plots the performance of various distance metrics and definitions
# of population size
#

# Plot dimensions
FIG_WIDTH = 5
FIG_HEIGHT = 6


library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--input"), action="store", default=NA, type='character',
              help="Path to file containing CPC performance metrics"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

metric_levels <- c("emb", 'gravmds', 'levyeuc', "svdcos", "lapcos", "pprjsd", 'gravsvd', "geo")
cpc <- read_csv(opt$input, col_types = readr::cols()) %>%
  mutate(metric = Distance) %>%
  filter(metric %in% metric_levels)

plot <- cpc %>%
  mutate(
    metric = factor(metric,
                    levels = rev(metric_levels),
                    labels = rev(c("Embedding\ncosine distance",
                               "Gravity MDS\nEuc. distance",
                               "Levy's Euc.\ndistance",
                               "SVD distance",
                               "Laplacian\neigenmap\ndistance",
                               "PPR JSD",
                               "Gravity SVD\ncosine distance",
                               "Geographic\ndistance"))),
  ) %>%
  gather(key, value, CPC_power, CPC_exp) %>%
  group_by(metric) %>%
  top_n(1, value) %>%
  ungroup() %>%
  mutate(metric = reorder(metric, value)) %>%
  ggplot(aes(x = value, y = metric)) +
  geom_point(size = 3, shape = 16) +
  geom_text(aes(label = round(value, 3)), nudge_y = 0.25) +
  scale_x_continuous(limits = c(0, 0.5)) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border = element_rect(size = 0.5, color = "black", fill = NA),
    text = element_text(size = 11, family = "Helvetica"),

    strip.text = element_text(size = 12, face = "bold"),
    strip.text.y.right = element_text(angle = 0, hjust = 0),
    axis.title = element_text(size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    axis.title.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title.y = element_blank(),
    axis.text.y = element_text(size = 12)
  )
# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

#
# PlotPrestigeRankCorrelation.R
#
# author: Dakota Murray
#
# Plot the numbers of publications over time
#

# Plot dimensions
FIG_WIDTH = 5
FIG_HEIGHT = 3


library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing the rank correlation data"),
  make_option(c("--ws"), action="store", default=NA, type='integer',
              help="The window size to plot"),
  make_option(c("--dim"), action="store", default=NA, type='integer',
              help="The dimensions to plot"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the trajectories
corr <- read_csv(opt$input, col_types = readr::cols()) %>%
  filter(traj == "precedence") %>%
  filter(dim == opt$dim) %>%
  filter(ws == opt$ws)

plot <- corr %>%
  mutate(
    # Update the labels
    ranking = factor(
      ranking,
      levels = c("leiden", "times"),
      labels = c("Leiden Ranking", "Times Ranking"))
  ) %>%
  ggplot(aes(x = n, y = rho)) +
  geom_point() +
  facet_wrap(~ranking) +
  theme_minimal() +
  theme(
    text = element_text(size = 11, family = "Helvetica"),
    strip.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(2, 'lines')

  ) +
  xlab("n") +
  ylab("Spearman's Rho")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

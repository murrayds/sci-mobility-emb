#
# PlotHyperparameterPerformance.R
#
# author: Dakota Murray
#
# Plots the performance of various hyper-parameters in explaining the flux
# between organizations.
#

# Plot dimensions
FIG_WIDTH = 7
FIG_HEIGHT = 4


library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing the aggregated hyperameter values"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the trajectories
params <- read_csv(opt$input, col_types = readr::cols())

plotdata <- params %>%
  filter(metric == "emb") %>%
  mutate(
    dim = factor(dim),
    case = factor(case,
                  levels = c("global", "same-country", "diff-country"),
                  labels = c("All Organizations", "Same Country", "Different Country")
                  )
    )


plot <- plotdata %>%
  ggplot(aes(x = ws, y = r2, color = dim, shape = dim, group = dim)) +
    geom_point(size = 3) +
    geom_line() +
    geom_linerange(aes(ymin = ci.lower, ymax = ci.upper)) +
    facet_grid(traj~case) +
    scale_color_manual(name = "Embedding Dimension", values = c("#b2bec3", "#636e72", "#2d3436")) +
    scale_shape_discrete(name = "Embedding Dimension") +
    theme_minimal() +
    theme(
      text = element_text(size = 11, family = "Helvetica"),
      strip.text = element_text(size = 12, face = "bold"),
      axis.title = element_text(size = 12),
      legend.title = element_text(size = 12, face = "bold"),
      legend.position = "bottom",
      panel.grid.major = element_blank(),
      panel.spacing = unit(1.5, "lines")
    ) +
    xlab("Window Size") +
    ylab("Correlation with flux")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

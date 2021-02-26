#
# PlotHyperparameterPerformance.R
#
# author: Dakota Murray
#
# Plots the performance of various hyper-parameters in explaining the flux
# between organizations.
#

# Plot dimensions
FIG_WIDTH = 6
FIG_HEIGHT = 6


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
  filter(sizetype == "all") %>%
  filter(traj == "precedence") %>%
  mutate(
    dim = factor(dim),
    ws = factor(ws),
    case = factor(case,
                  levels = c("global", "same-country", "diff-country"),
                  labels = c("All Organizations", "Same Country", "Different Country")
                ),
    gamma = factor(gamma),
    gamma = factor(gamma,
                   levels = c(0.75, 1.0),
                   labels = c("gamma = 0.75", "gamma = 1.0")
            )
  )


plot <- plotdata %>%
  ggplot(aes(x = dim, y = r2, color = ws, shape = ws, group = ws)) +
    geom_point(size = 3) +
    geom_line() +
    geom_linerange(aes(ymin = ci.lower, ymax = ci.upper)) +
    facet_grid(case~gamma) +
    scale_y_continuous(
      limits = c(0.2, 0.6),
      breaks = c(0.2, 0.4, 0.6)
    ) +
    scale_color_manual(
      name = "Window size",
      values = c("#b2bec3", "#636e72", "#2d3436")
    ) +
    scale_shape_discrete(name = "Window size") +
    theme_minimal() +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.border = element_rect(size = 0.5, color = "black", fill = NA),
      text = element_text(size = 11, family = "Helvetica"),
      strip.text = element_text(size = 12, face = "bold"),
      strip.text.y.right = element_text(angle = 0, hjust = 0),
      axis.title = element_text(size = 12),
      legend.title = element_text(size = 12, face = "bold"),
      legend.position = "bottom",
    ) +
    xlab("Embedding dimension") +
    ylab("Correlation with flux (R2)")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

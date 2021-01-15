#
# PlotDistanceMetricPerformance.R
#
# author: Dakota Murray
#
# Plots the performance of various distance metrics and definitions
# of population size
#

# Plot dimensions
FIG_WIDTH = 6
FIG_HEIGHT = 7


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

# Read the aggregate R2 data
params <- read_csv(opt$input, col_types = readr::cols())

plotdata <- params %>%
  filter(dim == 300) %>%
  filter(ws == 1) %>%
  filter(gamma == 1.0) %>%
  mutate(
    sizetype = gsub(".csv", "", sizetype, fixed = T),
    metric = factor(metric,
                    levels = c("geo", "emb", "dot", "pprcos", "pprjsd", "lapcos", "svdcos"),
                    labels = c("Geographic\ndistance", "Embedding\ncosine distance", "Embedding\ndot product", "PPR cosine\ndistance", "PPR JSD", "Laplacian\nEigenmap\ndistance", "SVD distance")),
    case = factor(case,
                  levels = c("global", "same-country", "diff-country"),
                  labels = c("All", "Domestic", "International")),
    sizetype = factor(sizetype,
                      levels = c("all", "mobile", "freq"),
                      labels = c("All", "Mobile only", "Raw frequency"))

  )


plot <- plotdata %>%
  ggplot(aes(x = sizetype, y = r2)) +
  geom_point(stroke = 0.2, size = 2.5, alpha = 0.8, position = position_dodge(0.5)) +
  facet_grid(metric~case) +
  scale_y_continuous(
    limits = c(0, 0.52),
    breaks = c(0, 0.25, 0.5)
  ) +
  scale_shape_manual(values = c(23, 21)) +
  scale_fill_manual(values = c("darkgrey", "black")) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border = element_rect(size = 0.5, color = "black", fill = NA),
    text = element_text(size = 11, family = "Helvetica"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 12, face = "bold"),
    strip.text.y.right = element_text(angle = 0, hjust = 0),
    axis.title = element_text(size = 12),
  ) +
  xlab("Definition of organization population") +
  ylab("Correlation with flux (R2)")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

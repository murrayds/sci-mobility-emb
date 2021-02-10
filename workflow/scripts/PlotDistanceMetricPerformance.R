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

metric_levels <- c("geo", "emb", "pprjsd", "lapcos", "svdcos", 'levyeuc')
plotdata <- params %>%
  filter(dim == 300) %>%
  filter(ws == 1) %>%
  filter(gamma == 1.0) %>%
  filter(metric %in% metric_levels) %>%
  mutate(
    sizetype = gsub(".csv", "", sizetype, fixed = T),
    metric = factor(metric,
                    levels = metric_levels,
                    labels = c("Geographic\ndistance", "Embedding\ncosine distance",
                                "PPR JSD", "Laplacian\neigenmap\ndistance",
                                "SVD distance", "Factorized euc.\ndistance")),
    # Reorder the metric variable with
    metric = reorder(metric, desc(r2)),
    case = factor(case,
                  levels = c("global", "same-country", "diff-country"),
                  labels = c("All", "Domestic", "International")),
    sizetype = factor(sizetype,
                      levels = c("all", "mobile", "freq"),
                      labels = c("All", "Mobile only", "Raw frequency"))

  )

# Get the top-performing for each set of parameters
top <- plotdata %>%
  group_by(sizetype, case) %>%
  filter(r2 == max(r2))

# build the plot
plot <- plotdata %>%
  ggplot(aes(x = sizetype, y = r2)) +
  geom_point(size = 2.5, alpha = 0.8, position = position_dodge(0.5), shape = 17) +
  geom_point(data = top, size = 1,
             aes(x = as.numeric(sizetype) + 0.15, y = r2 + 0.05),
             shape = 8, position = position_dodge(0.5)) +
  facet_grid(metric~case) +
  scale_y_continuous(
    limits = c(0, 0.55),
    breaks = c(0, 0.25, 0.5)
  ) +
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

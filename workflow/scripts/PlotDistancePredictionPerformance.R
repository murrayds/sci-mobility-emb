#
# PlotDistancePredictionPerformance.R
#
# author: Dakota Murray
#
# Plots the error of predictions made with various distance metrics
# and measures of population size
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
errors <- read_csv(opt$input, col_types = readr::cols())

metric_levels <- c("geo", "emb", "pprjsd", "lapcos", "svdcos", 'levyeuc')
plotdata <- errors %>%
  filter(dim == 300) %>%
  filter(ws == 1) %>%
  filter(gamma == 1.0) %>%
  filter(metric %in% metric_levels) %>%
  tidyr::gather(model, rmse, error.exp, error.power) %>%
  mutate(
    model = gsub("(error.)", "", model),
    sizetype = gsub(".csv", "", sizetype, fixed = T),
    metric = factor(metric,
                    levels = metric_levels,
                    labels = c("Geographic\ndistance", "Embedding\ncosine distance",
                                "PPR JSD", "Laplacian\neigenmap\ndistance",
                                "SVD distance", "Factorized euc.\ndistance")),
    # Reorder the metric variable with
    metric = reorder(metric, rmse),
    case = factor(case,
                  levels = c("global", "same", "different"),
                  labels = c("All", "Domestic", "International")),
    sizetype = factor(sizetype,
                      levels = c("all", "mobile", "freq"),
                      labels = c("All", "Mobile only", "Raw frequency")),
    model = factor(model,
                    levels = c("exp", "power"),
                    labels = c("Exponential", "Power-law"))

  )

# Get the top-performing for each set of parameters
# Now, this is a little hacky, becuase position_dodge below requires a point
# for -every- row, not just the top performing, in order to layout the asteriks
# correctly. As such, I am making a new variable to color the points with, and
# making non-top astericks blank (alpha set to zero)
top <- plotdata %>%
  group_by(sizetype, case, model) %>%
  mutate(model2 = ifelse(rmse == min(rmse), as.character(model), "xyz"))

# build the plot
plot <- plotdata %>%
  ggplot(aes(x = sizetype, y = rmse, fill = model, group = model)) +
  geom_point(size = 2.5, alpha = 0.8, shape = 25, position = position_dodge(0.5)) +
  geom_point(data = top, size = 1,
             aes(x = as.numeric(sizetype) + 0.08, y = rmse + 0.1, color = model2, fill = NULL),
             position = position_dodge2(0.5, preserve = "total"),
             shape = 8, show.legend = FALSE) +
  facet_grid(metric~case) +
  scale_y_continuous(
    limits = c(0.5, 1.1),
    breaks = c(0.5, 0.75, 1.0)
  ) +
  scale_fill_manual(values = c("darkgrey", "black")) +
  scale_color_manual(values = c("darkgrey", "black", "white"), guide = F) +
  scale_alpha_manual(values = c(1.0, 1.0, 0)) +
  guides(alpha = F, color = F) +
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
    legend.position = "bottom",
    legend.title = element_blank()
  ) +
  xlab("Definition of organization population") +
  ylab("Root Mean Squared Error (RMSE)")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

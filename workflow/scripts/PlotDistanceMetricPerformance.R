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
FIG_HEIGHT = 4.5


library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--r2"), action="store", default=NA, type='character',
              help="Path to file containing the aggregated r2 values"),
  make_option(c("--rmse"), action="store", default=NA, type='character',
              help="Path to file containing the aggregated RMSE values"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregate R2 data
r2 <- read_csv(opt$r2, col_types = readr::cols()) %>%
  select(r2, traj, metric, case, dim, ws, gamma, sizetype) %>%
  mutate(
    type = "r2",
    performance = "Flux explained (correlation)"
  ) %>%
  rename(value = r2)

rmse <- read_csv(opt$rmse, col_types = readr::cols()) %>%
  select(error.exp, error.power, traj, metric, case, dim, ws, gamma, sizetype) %>%
  gather(type, value, error.exp, error.power) %>%
  mutate(performance = "Root mean squared error")

# The metrics to focus on for this plot
metric_levels <- c("emb", 'gravmds', 'levyeuc', "svdcos", "lapcos", "pprjsd", 'gravsvd', "geo")

plotdata <- data.table::rbindlist(list(r2, rmse), use.names = T) %>%
  filter(dim == 300) %>%
  filter(ws == 1) %>%
  filter(gamma == 1.0) %>%
  filter(sizetype == "all") %>%
  filter(case == "global") %>%
  filter(metric %in% metric_levels) %>%
  mutate(
    metric = factor(metric,
                    levels = rev(metric_levels),
                    labels = rev(c("Embedding\ncosine distance",
                               "Gravity MDS\neuc. distance",
                               "Factorized euc.\ndistance",
                               "SVD distance",
                               "Laplacian\neigenmap\ndistance",
                               "PPR JSD",
                               "Gravity SVD\ncosine distance",
                               "Geographic\ndistance"))),
    type = factor(type,
                  levels = c("r2", "error.power", "error.exp"),
                  labels = c("Flux explained",
                             "Prediction error\n(Power-law model)",
                             "Prediction error\n(Exponential model)"))
  )

# Get the top-performing for each set of parameters
top <- plotdata %>%
  group_by(type) %>%
  filter((type == "Flux explained" & value == max(value)) | (type != "Flux explained" & value == min(value)))

# build the plot
plot <- plotdata %>%
  ggplot(aes(x = value, y = metric, fill = type, shape = type)) +
  geom_point(size = 2.5, alpha = 0.8,
             position = position_dodge(0.75)) +
  geom_point(data = top, size = 1,
             aes(y = as.numeric(metric) + 0.1, x = value + 0.05, fill = type, shape = type),
             position = position_dodge(0.75),
             shape = 8, show.legend = FALSE) +
  geom_text(aes(label = round(value, 2)), size = 2.5, hjust = -1,
            position = position_dodge(0.75)) +
  facet_wrap(~performance) +
  scale_x_continuous(
    limits = c(0, 1.15),
    breaks = c(0, 0.25, 0.5, 0.75, 1.0)
  ) +
  scale_shape_manual(values = c(23, 24, 25)) +
  scale_fill_manual(values = c("black", "darkgrey", "white")) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    panel.border = element_rect(size = 0.5, color = "black", fill = NA),
    text = element_text(size = 11, family = "Helvetica"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 12, face = "bold"),
    strip.text.y.right = element_text(angle = 0, hjust = 0),
    #axis.title = element_text(size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    #legend.key.height = unit(1.5, "cm"),
    axis.title = element_blank()
  )

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

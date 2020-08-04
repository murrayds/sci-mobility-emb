#
# PlotPrestigeRankCorrelation.R
#
# author: Dakota Murray
#
# Plot the numbers of publications over time
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
              help="Path to file containing the rank correlation data"),
  make_option(c("--ws"), action="store", default=NA, type='integer',
              help="The window size to plot"),
  make_option(c("--dim"), action="store", default=NA, type='integer',
              help="The dimensions to plot"),
  make_option(c("--ranking"), action="store", default=NA, type='character',
              help="Ranking to filter to, either times or leiden"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the trajectories
corr <- read_csv(opt$input, col_types = readr::cols()) %>%
  filter(traj == "precedence") %>%
  filter(dim == opt$dim) %>%
  filter(ws == opt$ws) %>%
  filter(ranking == opt$ranking) %>%
  tidyr::gather(key, value, rho, rho.excluded)


plot <- corr %>%
  mutate(
    key = factor(key,
                 levels = c("rho", "rho.excluded"),
                 labels = c("All orgs", "Non-axis orgs"))
  ) %>%
  ggplot(aes(x = n, y = value, fill = key, shape = key, linetype = key)) +
  geom_line() +
  geom_point(size = 3) +
  scale_shape_manual(values = c(16, 21)) +
  #scale_color_manual(values = c("black", "white")) +
  scale_fill_manual(values = c("black", "white")) +
  scale_y_continuous(
    limits = c(0.4, 1.0),
    expand = c(0, 0),
    breaks = c(0.4, 0.6, 0.8, 1.0),
    labels = c("0.40", "0.60", "0.80", "1.0")
  ) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    strip.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(2, 'lines'),
    legend.position = c(0.3, 0.2),
    legend.background = element_rect(colour="black", fill="white"),
    legend.title = element_blank()
  ) +
  xlab("Number of organizations used to define axis") +
  ylab(latex2exp::TeX("Spearman's $\\rho"))

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

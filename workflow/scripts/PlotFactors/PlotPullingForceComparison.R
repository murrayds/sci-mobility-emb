#
# PlotPullingForceComparison.R
#
# author: Dakota Murray
#
# Compare the pulling force of the in and out vectors, s_i and s_j
# They should be highly correlated
#

# Plotting options
REGRESSION_LINE_COLOR = "#c0392b"

# Plot dimensions
FIG_WIDTH = 3
FIG_HEIGHT = 3

library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing model factor values"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load data
factors <- readr::read_csv(opt$input, col_types = readr::cols())

# Draw the plot
plot <- factors %>%
  ggplot(aes(x = s_i, y = s_j)) +
  geom_point() +
  # Draw a regression line
  stat_smooth(method = "lm",
              formula = y ~ x,
              color = REGRESSION_LINE_COLOR,
              size = 1,
              fullrange = T) +
  ggpmisc::stat_poly_eq(formula = y ~ x,
                        geom = "text_npc",
                        aes(label = paste(..rr.label.., sep = "~~~")),
                        parse=TRUE,
                        label.x.npc = 0.10,
                        rr.digits = 2,
                        size = 7
  ) +
  scale_x_log10(labels = function(x) { parse(text=paste0("10^", log10(x))) }) +
  scale_y_log10(labels = function(x) { parse(text=paste0("10^", log10(x))) }) +
  theme_minimal() +
  theme(
    aspect.ratio = 1,
    text = element_text(family = "Helvetica", size = 12),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_rect(size = 1, fill = NA)
  ) +
  xlab(bquote(~log[10]~(s['in']))) +
  ylab(bquote(~log[10]~(s['out'])))


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

#
# PlotPotentialVsPi.R
#
# author: Dakota Murray
#
# Compare the gravitation potential against the \pi estimate
#

# Plotting options
NUM_HEX_BINS = 20

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

plot <- factors %>%
  ggplot(aes(x = gravity_potential, y = pi_i)) +
  geom_hex(bins = 20,
             aes(fill = stat(log10(count))),
             size = 0 # remove boundary
  ) +
  scale_x_log10(labels = function(x) { parse(text=paste0("10^", log10(x))) }) +
  scale_y_log10() +
  # Set the color gradient
  scale_fill_gradientn(colours=c("white", "#7f8c8d"),
                       name = "Frequency",
                       breaks = c(0, 1, 2),
                       labels = function(x) { parse(text=paste0("10^", x)) },
                       na.value=NA
  ) +
  # Draw a regression line
  stat_smooth(method = "lm",
              formula = y ~ x,
              color = REGRESSION_LINE_COLOR,
              size = 1.5,
              fullrange = T) +
  ggpmisc::stat_poly_eq(formula = y ~ x,
                        geom = "text_npc",
                        aes(label = paste(..rr.label.., sep = "~~~")),
                        parse=TRUE,
                        label.x.npc = 0.05,
                        rr.digits = 1,
                        size = 7
  ) +
  theme_minimal() +
  theme(
    aspect.ratio = 1,
    text = element_text(family = "Helvetica", size = 12),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_rect(size = 1, fill = NA)
  ) +
  xlab(bquote(~log[10]~(phi))) +
  ylab(bquote(~log[10]~(pi['i'])))

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))


# Save the plot
ggsave(opt$output, p)

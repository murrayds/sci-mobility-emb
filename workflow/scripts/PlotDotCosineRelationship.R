#
# PlotDotCosineRelationship.R
#
# author: Dakota Murray
#

# Plotting options
NUM_HEX_BINS = 20
NUM_DISTANCE_BINS = 30

FILL_GRADIENT_MIN = "white"
FILL_GRADIENT_MAX = "#7f8c8d"
BIN_BORDER_COLOR = "white"

LEGEND_POSITION = "right" # can be "right", "bottom", "left", or None

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
              help="Path to file containing aggregate organization distances"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregated distance file
dist = readr::read_csv(opt$input, col_types = readr::cols()) %>%
  filter(count > 0) %>%
  select(dot_distance, emb_distance)

# Create binned values that will be plotted over top
dist_binned <- dist %>%
  mutate(
    bin = cut(round(emb_distance, 2), NUM_DISTANCE_BINS)
  ) %>%
  arrange(bin) %>%
  group_by(bin) %>%
  summarize(
    # Plot the point at the midpoint in each bin
    pos = min(emb_distance) + ((max(emb_distance) - min(emb_distance)) / 2),
    #pos = (as.numeric(first(bin)) * 0.05) - 0.025,
    mu = mean(dot_distance, na.rm = T),
    ci = 2.576 * (sd(dot_distance, na.rm = T) / sqrt(n())) # using the 99th percentile CI
  )

# Build the plot object
plot <- dist %>%
  ggplot(aes(x = emb_distance, y = dot_distance)) +
    geom_hex(bins = NUM_HEX_BINS,
             aes(fill = stat(log10(count))),
             size = 0 # remove boundary
    ) +
    # Draw a regression line
    stat_smooth(method = "lm",
                formula = y ~ x,
                color = REGRESSION_LINE_COLOR,
                size = 1.5,
                fullrange = T) +
    # Add the r-squared coefficient to the plot
    ggpmisc::stat_poly_eq(formula = y ~ x,
                          geom = "text_npc",
                          aes(label = paste(..rr.label.., sep = "~~~")),
                          parse = TRUE,
                          label.x.npc = 0.85,
                          rr.digits = 2,
                          size = 7
    ) +
    # Add mean + 99% confidence intervals for each bin of data
    geom_pointrange(data = dist_binned,
                    aes(x = pos, y = mu, ymin = mu - ci, ymax = mu + ci),
                    size = 0.5,
                    fatten = 0.9) +
    # Set the color gradient
    scale_fill_gradientn(colours=c(FILL_GRADIENT_MIN, FILL_GRADIENT_MAX),
                         name = "Frequency",
                         breaks = c(0, 1, 2, 3, 4, 5),
                         limits = c(0, 5),
                         labels = function(x) { parse(text=paste0("10^", x)) },
                         na.value=NA
    ) +
    coord_fixed() +
    #guides(fill = F) +
    scale_x_continuous(breaks = c(0, 0.5, 1),
                       limits = c(0, 1),
                       labels = c("0", "0.5", "1"),
                       expand = c(0, 0)
    ) +
    scale_y_continuous(breaks = c(0, 20, 40),
                       limits = c(0, 40)
    ) +
    # Define the plotting theme
    theme_minimal() +
    theme(
      aspect.ratio = 1,
      legend.position = "right",
      legend.title = element_text(size = 15),
      legend.text = element_text(size = 13),
      axis.title.y = element_text(size = 15),
      axis.title.x = element_text(size = 15),
      axis.text = element_text(size = 13),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      panel.border = element_rect(colour = "black", fill=NA, size=1)
    ) +
    # Add labels
    xlab("Cosine distance") +
    ylab("Dot product similarity")

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))

# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 2.4, height = FIG_HEIGHT + 1.8)

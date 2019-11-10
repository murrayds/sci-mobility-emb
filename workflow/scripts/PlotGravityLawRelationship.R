#
# PlotGravityLawRelationship.R
#
# author: Dakota Murray
#
# Visualize how well embedding distance explains the gravity law, compared
# to geographic distance.
#

# Plotting options
NUM_BINS = 20

FILL_GRADIENT_MIN = "white"
FILL_GRADIENT_MAX = "blue"
BIN_BORDER_COLOR = "lightgrey"

LEGEND_POSITION = "right" # can be "right", "bottom", "left", or None

REGRESSION_LINE_COLOR = "#c0392b"

# Plot dimensions
FIG_WIDTH = 9
FIG_HEIGHT = 5

library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing aggregate organization distances"),
  make_option(c("--filter"), action="store_true", default=FALSE,
              help="If set, don't plot imputed values"),
  make_option(c("--reg"), action="store_true", default=FALSE,
              help="If set, draw regression line"),
  # These are mostly unecessary, but make automation easier since we can just
  # iterate over different flafs
  make_option(c("--noreg"), action="store_false", default=FALSE, dest = "reg",
              help="If set, don't draw regression line"),
  make_option(c("--nofilter"), action="store_false", default=FALSE, dest = "filter",
              help="If set, plot imputed values"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregated distance file
dist = readr::read_csv(opt$input, col_types = readr::cols())

# If the filter flag is set, then filter the data to exclude imputed values,
# or those for which the original count was equal to 0.
if (opt$filter) {
    dist <- dist %>%
      filter(count > 0)
}


# Build the plot object
plot <- dist %>%
  # First log the geographic distance and the axes
  mutate(geo_distance_logged = log(geo_distance),
         gravity_logged = log(gravity)
         ) %>%
  # Convert to long format
  tidyr::gather(metric, distance, geo_distance_logged, emb_similarity) %>%
  # Rename the distance and similarity measure
  mutate(metric = factor(metric,
                         levels = c("geo_distance_logged", "emb_similarity"),
                         labels = c("log(km distance)", "cosine similarity"))
  ) %>%
  # Start the GGPLOT code
  ggplot(aes(x = gravity_logged, y = distance)) +
    geom_hex(bins = NUM_BINS,
           color = BIN_BORDER_COLOR) +
    facet_wrap(~metric, scale = "free_y", strip.position = "left") +
    theme_minimal() +
    scale_fill_gradientn(colours=c(FILL_GRADIENT_MIN, FILL_GRADIENT_MAX),
                        name = "Frequency",
                        na.value=NA) +
    theme(
      legend.position = "right",
      strip.text = element_text(size = 12),
      axis.title.x = element_text(size = 12, face = "bold"),
      axis.title.y = element_blank()
    ) +
    xlab(latex2exp::TeX("$\\log\\left(\\frac{F_{ij}}{P_{i}P_{j}}\\right)$")) +
    ylab("Metric")

# If the "reg" option is set, then draw a regression line with the correponding
# value of R2
if (opt$reg) {
  plot <- plot +
    stat_smooth(method = "lm", formula = y ~ x, color = REGRESSION_LINE_COLOR, size = 1.5) +
    ggpmisc::stat_poly_eq(formula = y ~ x,
                          aes(label = paste(..rr.label.., sep = "~~~")),
                          parse=TRUE,
                          coef.digits = 2,
                          label.x.npc = "right")
}

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

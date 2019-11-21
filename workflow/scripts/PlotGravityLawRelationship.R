#
# PlotGravityLawRelationship.R
#
# author: Dakota Murray
#
# Visualize how well embedding distance explains the gravity law, compared
# to geographic distance.
#

# Plotting options
NUM_HEX_BINS = 20
NUM_DISTANCE_BINS = 40

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
  make_option(c("--geo"), action="store", default="none",
              help="Geographic constraint, none, or same or different country, region, or city"),
  # These are mostly unecessary, but make automation easier since we can just
  # iterate over different items in a list
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

# Format the distance dataframe, calculating necessary values
dist <- dist %>%
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
  )

# If the geographic constraint (--geo) is set, then filter the
# distance dataframe accordingly.
if (opt$geo == "same-country") {
  dist <- dist %>% filter(org1_country == org2_country)
} else if (opt$geo == "same-region") {
  dist <- dist %>% filter(org1_region == org2_region)
} else if (opt$geo == "different-country") {
  dist <- dist %>% filter(org1_country != org2_country)
} else if (opt$geo == "different-region") {
  dist <- dist %>% filter(org1_region != org2_region)
} else if (opt$geo == "different-city") {
  dist <- dist %>% filter(org1_city != org2_city)
}

# Create binned values that will be plotted over top
dist_binned <- dist %>%
  group_by(metric) %>%
  mutate(
    bin = cut(round(distance, 2), NUM_DISTANCE_BINS)
  ) %>%
  arrange(bin) %>%
  group_by(metric, bin) %>%
  summarize(
    # Plot the point at the midpoint in each bin
    pos = min(distance) + ((max(distance) - min(distance)) / 2),
    #pos = (as.numeric(first(bin)) * 0.05) - 0.025,
    mu = mean(gravity_logged, na.rm = T),
    ci = 2.576 * (sd(gravity_logged, na.rm = T) / sqrt(n())) # using the 99th percentile CI
  )

# Build the plot object
plot <- dist %>%
  ggplot(aes(x = distance, y = gravity_logged)) +
    geom_hex(bins = NUM_HEX_BINS,
             color = BIN_BORDER_COLOR) +
    # Break into facets, but labels on bottom, allow different x axes
    facet_wrap(~metric, scale = "free_x", strip.position = "bottom") +
    # Draw a regression line
    stat_smooth(method = "lm", formula = y ~ x, color = REGRESSION_LINE_COLOR, size = 1.5) +
    # Add the r-squared coefficient to the plot
    ggpmisc::stat_poly_eq(formula = y ~ x,
                          aes(label = paste(..rr.label.., sep = "~~~")),
                          parse=TRUE,
                          coef.digits = 2,
                          label.x.npc = "right"
    ) +
    # Add mean + 99% confidence intervals for each bin of data
    geom_point(data = dist_binned, aes(x = pos, y = mu, group = bin), size = 2) +
    geom_errorbar(data = dist_binned, aes(x = pos, ymin = mu - ci, ymax = mu + ci, y = NULL)) +
    # Set the color gradient
    scale_fill_gradientn(colours=c(FILL_GRADIENT_MIN, FILL_GRADIENT_MAX),
                        name = "Frequency",
                        na.value=NA
    ) +
    # Define the plotting theme
    theme_minimal() +
    theme(
      legend.position = "right",
      strip.text = element_text(size = 12),
      axis.title.y = element_text(size = 12, face = "bold", angle = 0, vjust = 0.5),
      axis.title.x = element_blank()
    ) +
    # Add labels
    ylab(latex2exp::TeX("$\\log\\left(\\frac{F_{ij}}{P_{i}P_{j}}\\right)$"))

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

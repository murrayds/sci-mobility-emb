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
FIG_WIDTH = 6
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
  make_option(c("--distance"), action="store", default="none",
              help="One of 'geo' or 'emb', specifying which distance metric of the dataframe to use"),
  make_option(c("--showcoef"), action="store_true", default=FALSE,
              help="If set, add R squared coefficient to the plot"),
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

# Reduce the size to save on memory
dist <- dist %>%
  select(geo_distance, emb_similarity, gravity)

axislabel <- "DEFAULT"
# Select the appropriate metric using the --distance command line argument

if (opt$distance == "geo") {
  dist <- dist %>%
    mutate(distance = log10(geo_distance))

  # Provide axis label
  axislabel <- "log(km distance)"
} else if (opt$distance == "emb") {
  # Default, use embedding distance
  dist <- dist %>%
    rename(distance = emb_similarity)

  # Provide axis label
  axislabel <- "cosine similarity"
}

# Calculate the logged gravity and select only relevant columns
dist <- dist %>%
  mutate(gravity_logged = log10(gravity)) %>%
  select(gravity_logged, distance)

# Create binned values that will be plotted over top
dist_binned <- dist %>%
  mutate(
    bin = cut(round(distance, 2), NUM_DISTANCE_BINS)
  ) %>%
  arrange(bin) %>%
  group_by(bin) %>%
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
             color = BIN_BORDER_COLOR,
             size = 0.15) +
    # Draw a regression line
    stat_smooth(method = "lm", formula = y ~ x, color = REGRESSION_LINE_COLOR, size = 1.5) +
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
      axis.title.y = element_text(size = 12, face = "bold", angle = 0, vjust = 0.5),
      axis.title.x = element_text(size = 12, face = "bold"),
      panel.grid.minor = element_blank(),
      axis.line = element_line(colour = "black")
    ) +
    # Add labels
    xlab(axislabel) +
    ylab(latex2exp::TeX("$\\log\\left(\\frac{F_{ij}}{P_{i}P_{j}}\\right)$"))


if (opt$showcoef) {
  plot <- plot +
    # Add the r-squared coefficient to the plot
    ggpmisc::stat_poly_eq(formula = y ~ x,
                          aes(label = paste(..rr.label.., sep = "~~~")),
                          parse=TRUE,
                          coef.digits = 2,
                          label.x = "left",
                          # The data is shaped differently, so move the metric
                          # accordingly based on where it falls
                          label.y = ifelse(opt$distance == "emb", "top", "bottom"),
                          size = 7
    )
}
# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

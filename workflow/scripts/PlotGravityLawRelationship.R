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
  select(geo_distance, emb_distance, dot_distance,
         pprcos_distance, pprjsd_distance,
         svdcos_distance, lapcos_distance,
         levycos_distance, levyeuc_distance, levydot_distance, gravity)

axislabel <- "DEFAULT"
# Select the appropriate metric using the --distance command line argument

if (opt$distance == "geo") {
  dist <- dist %>%
    mutate(distance = log10(geo_distance))

  # Provide axis label
  axislabel <- "Distance (km)"
} else if (opt$distance == "emb") {
  # Default, use embedding distance
  dist <- dist %>%
    rename(distance = emb_distance) %>%
    mutate(distance = ifelse(distance > 0, distance, 0))

  # Provide axis label
  axislabel <- "Cosine distance"
} else if (opt$distance == "pprcos") {
  dist <- dist %>%
    rename(distance = pprcos_distance)

  # Provide axis label
  axislabel <- "PPR cosine distance"
} else if (opt$distance == "pprjsd") {
  dist <- dist %>%
    rename(distance = pprjsd_distance)

  # Provide axis label
  axislabel <- "PPR Jensen-Shannon"
} else if (opt$distance == "dot") {
  dist <- dist %>%
    rename(distance = dot_distance)

  # Provide axis label
  axislabel <- "Dot product similarity"
} else if (opt$distance == "svdcos") {
  dist <- dist %>%
    rename(distance = svdcos_distance)

  # Provide axis label
  axislabel <- "SVD cosine distance"
} else if (opt$distance == "lapcos") {
  dist <- dist %>%
    rename(distance = lapcos_distance)

  # Provide axis label
  axislabel <- "Laplacian cosine distance"
} else if (opt$distance == "levycos") {
  dist <- dist %>%
    rename(distance = levycos_distance)

  # Provide axis label
  axislabel <- "Levy's cosine distance"
} else if (opt$distance == "levyeuc") {
  dist <- dist %>%
    rename(distance = levyeuc_distance)

  # Provide axis label
  axislabel <- "Levy's euclidean distance"
} else if (opt$distance == "levydot") {
  dist <- dist %>%
    rename(distance = levydot_distance)

  # Provide axis label
  axislabel <- "Levy's dot distance"
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
             aes(fill = stat(log10(count))),
             size = 0 # remove boundary
    ) +
    # Draw a regression line
    stat_smooth(method = "lm",
                formula = y ~ x,
                color = REGRESSION_LINE_COLOR,
                size = 1.5,
                fullrange = T) +
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
    guides(fill = F) +
    scale_y_continuous(breaks = c(-8, -6, -4, -2, 0),
                       labels = function(x) { parse(text = paste0("10^", x)) },
                       limits = c(-8, 0)
    ) +
    # Define the plotting theme
    theme_minimal() +
    theme(
      aspect.ratio = 1,
      legend.position = "right",
      legend.title = element_text(size = 15),
      legend.text = element_text(size = 13),
      axis.title.y = element_text(size = 15, angle = 0, vjust = 0.5),
      axis.title.x = element_text(size = 15),
      axis.text = element_text(size = 13),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      panel.border = element_rect(colour = "black", fill=NA, size=1)
    ) +
    # Add labels
    xlab(axislabel) +
    ylab(latex2exp::TeX("\\textit{$\\frac{T_{ij}}{m_{i}m_{j}}$}"))


#
# Add an x-axis scale based on the type of distance metric being used
#
if (opt$distance == "geo") {
  plot <- plot +
    scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5),
                       limits = c(0, 5),
                       labels = function(x) { parse(text=paste0("10^", x)) },
                       expand = c(0, 0)
                     )
} else if (opt$distance == "emb" | grepl("ppr", opt$distance, fixed = TRUE) == T) {
  plot <- plot +
    scale_x_continuous(breaks = c(0, 0.5, 1),
                       limits = c(0, 1),
                       labels = c("0", "0.5", "1"),
                       expand = c(0, 0)
                     )
}

if (opt$showcoef) {
  plot <- plot +
    # Add the r-squared coefficient to the plot
    ggpmisc::stat_poly_eq(formula = y ~ x,
                          geom = "text_npc",
                          aes(label = paste(..rr.label.., sep = "~~~")),
                          parse=TRUE,
                          label.x.npc = ifelse(
                            grepl("ppr", opt$distance, fixed = TRUE) | grepl("dot", opt$distance, fixed = TRUE),
                            0.05, 0.95
                          ),
                          label.y.npc = 0.96,
                          rr.digits = 2,
                          size = 7
    )
}

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))

# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

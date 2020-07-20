#
# PlotPredictedVsActual.R
#
# author: Dakota Murray
#
# Plot the relationship between predicted and actual flows
#

# Plotting options
NUM_BINS = 36

COLOR_BAD_FIT = "white"
COLOR_GOOD_FIT = "#1E88E5"

FILL_GRADIENT_MIN = "white"
FILL_GRADIENT_MAX = "#7f8c8d"
BIN_BORDER_COLOR = "white"

# Plot dimensions
FIG_WIDTH = 3
FIG_HEIGHT = 3

library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing predicted vs. actual flows"),
  make_option(c("--geo"), action="store", default="none",
              help="Geographic constraint, none, or same or different country"),
  make_option(c("--model"), action="store", default="none",
              help="Model type, either exponential (exp) or power decay (power)"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregated distance file
data = readr::read_csv(opt$input, col_types = readr::cols())

# If the geographic constraint (--geo) is set, then filter the
# distance dataframe accordingly.
if (opt$geo == "same-country") {
  data <- data %>% filter(org1_country == org2_country)
} else if (opt$geo == "different-country") {
  data <- data %>% filter(org1_country != org2_country)
}

# Set the correct distance variable based on input parameter
if (opt$model == "exp") {
  data <- data %>%
    mutate(expected = expected.exp)
} else if (opt$model == "power") {
  data <- data %>%
    mutate(expected = expected.power)
}

# Create bins for epected values within which we will calculate
# aggregate information about the actual values.
binned <- data %>%
  # Filter to within a specific range to avoid outlier issues
  filter(log10(expected) < 6 & log10(expected) >= 0) %>%
  filter(log10(actual) < 6 & log10(actual) >= 0) %>%
  mutate(
    expected = log10(expected),
    actual = log10(actual),
    bin = cut(expected, NUM_BINS)
  ) %>%
  arrange(bin) %>%
  group_by(bin) %>%
  summarize(
    # Plot the point at the midpoint in each bin
    bin_char = first(gsub("(?![,.])[[:punct:]]", "", as.character(bin), perl=TRUE)),
    bin_min = as.numeric(unlist(strsplit(bin_char, ","))[1]),
    bin_max = as.numeric(unlist(strsplit(bin_char, ","))[2]),
    pos = bin_min + (bin_max - bin_min),
    mu = mean(actual, na.rm = T),
    med = median(actual, na.rm = T),
    # Percentile ranges of the bin
    percentile_upper = quantile(actual, probs = c(0.75), na.rm = T)[1],
    percentile_max = quantile(actual, probs = c(0.85), na.rm = T)[1],
    percentile_lower = quantile(actual, probs = c(0.25), na.rm = T)[1],
    percentile_min = quantile(actual, probs = c(0.15), na.rm = T)[1],
    # logical, whether or not the percentile crosses the line x = y
    crosses_ab_strong = (percentile_upper > pos & pos > mu) | (percentile_lower < pos & pos < mu),
    crosses_ab_weak = (percentile_max > pos & pos > mu) | (percentile_min < pos & pos < mu),
  )

error <- sqrt(mean((log10(data$expected) - log10(data$actual)) ^ 2, na.rm = T))

# Build the plot
plot <- data %>%
  ggplot(aes(x = log10(expected), y = log10(actual))) +
  # Represent the plot using log-transformed hex-bins, rather than points
  geom_hex(bins = 20,
           aes(fill = stat(log10(count))),
           size = 0) +
  geom_abline(color = "black", size = 1.2) +
  # Draw the boxplots for each "bin" of the data
  geom_boxplot(data = binned,
               size = 0.3,
               stat = "identity",
               fill = ifelse(binned$crosses_ab_strong, "#1E88E5",
                             ifelse(binned$crosses_ab_weak, "#81ecec", "white")),
               color = "black",
               aes(x = pos,
                   y = NULL,
                   ymin = percentile_min,
                   lower = percentile_lower,
                   middle = med,
                   upper = percentile_upper,
                   ymax = percentile_max,
                   group = bin)
  ) +
  # Add points designating the mean of each bin
  geom_point(data = binned,
             aes(x = pos, y = mu),
             color = "black",
             size = 1.5,
             shape = 21,
             stroke = 0.8) +
  # Set axis scales
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5, 6),
                     limits = c(-1, 7),
                     labels = function(x) { parse(text=paste0("10^", x)) },
                     expand = c(0, 0)) +
  scale_y_continuous(breaks = c(0, 1, 2, 3, 4, 5, 6),
                     limits = c(-1, 7),
                     labels = function(x) { parse(text=paste0("10^", x)) },
                     expand = c(0, 0)) +
  coord_fixed() +
  annotate(geom = "text",
           x = 1.6,
           y = 6.2,
           label = paste0("RMSE = ", sprintf("%.2f", round(error,3))),
           size = 7
         ) +
  # Define the gradient
  scale_fill_gradientn(colours=c(FILL_GRADIENT_MIN, FILL_GRADIENT_MAX),
                       name = "Frequency",
                       breaks = c(0, 1, 2, 3, 4, 5),
                       limits = c(0, 5),
                       labels = function(x) { parse(text=paste0("10^", x)) },
                       na.value=NA
  ) +
  guides(alpha = F, fill = F, color = F) +
  theme_minimal() +
  theme(
    aspect.ratio = 1, # ensure a square plot
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13),
    panel.border = element_rect(colour = "black", fill=NA)
  ) +
  xlab("Flux (predicted)") +
  ylab("Flux (data)")


p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

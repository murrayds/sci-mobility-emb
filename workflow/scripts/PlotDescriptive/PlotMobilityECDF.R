#
# PlotPubsOverTime.R
#
# author: Dakota Murray
#
# Plot the reverse ECDF of the number of affiliations for mobile researchers
#

# Plot dimensions
FIG_WIDTH = 6
FIG_HEIGHT = 5

library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing researcher metadata"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))


researchers.meta <- read_delim(opt$input, delim = "\t", col_types = readr::cols()) %>%
  select(cluster_id, num_org, num_city, num_region, num_country) %>%
  filter(num_org > 1) # Filter to org-mobile researchers

# Convert data to long format and add define factor levels
researchers.meta.long <- researchers.meta %>%
  tidyr::gather(key, value, num_org, num_city, num_region, num_country) %>%
  mutate(
    key = factor(key,
                   levels = c("num_org", "num_city", "num_region", "num_country"),
                   labels = c("Organization", "City", "Region", "Country"))
  )


# Separate df containing values for labels on the plot
labels <- researchers.meta.long %>%
  group_by(key) %>%
  summarize(
    ypos = (sum(value > 1) / n()),
    cumulative = (sum(value > 1) / n())
  )


# Draw the plot
plot <- researchers.meta.long %>%
  ggplot(aes(x = value, group = key)) +
  # Create a reverse ECDF Line
  geom_step(aes(y = 1 - ..y..), stat='ecdf') +
  # Add labels at x = 2 stating the proportion of mobile researchers
  ggrepel::geom_label_repel(
    data = labels,
    aes(x = 2,
        y = ypos,
        label = format(round(cumulative, 2), nsmall = 2)),
    min.segment.length = 0.1,
    force = 0,
    nudge_x = 1, nudge_y = 0.2,
    segment.color = "grey",
    segment.size = 0.25
  ) +
  # Split into sub-plots for org, city, region, and country
  facet_wrap(~key, nrow = 2, ncol = 2) +
  scale_x_continuous(breaks = c(1, 3, 5, 7, 9), limits = c(1, 9)) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1.0), limits = c(-0.1, 1.1)) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    strip.text = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(size = 0.5)
  ) +
  xlab("# affiliations per researcher") +
  ylab("Fraction of researchers")


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

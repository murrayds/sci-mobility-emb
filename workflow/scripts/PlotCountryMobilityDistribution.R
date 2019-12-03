#
# PlotCountryMobilityDistribution.R
#
# author: Dakota Murray
#
# Plot the distirbution of country's based on their contribution to
# global mobility
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
  make_option(c("-f", "--flows"), action="store", default=NA, type='character',
              help="Path to file containing career trajectories"),
  make_option(c("l", "--lookup"),, action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("r", "--researchers"),, action="store", default=NA, type='character',
              help="Path to file containing researcher metadata"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load organization meta-info
lookup <- read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  select(cwts_org_no, country_iso_alpha, city)

researchers <- read_delim(opt$researchers, delim = "\t", col_types = readr::cols()) %>%
  select(cluster_id, org_mobile, country_mobile)

# Load the flows and aggregate
flows <- read_delim(opt$flows, delim = "\t", col_types = readr::cols()) %>%
  select(-LR_main_field_no, -pub_year) %>%
  left_join(researchers, by = "cluster_id") %>%
  left_join(lookup, by = "cwts_org_no") %>%
  group_by(country_iso_alpha, org_mobile) %>%
  summarize(
    count = length(unique(cluster_id))
  )

# Build data for the plot
plotdata <- flows %>%
  filter(org_mobile) %>%
  ungroup() %>%
  mutate(
    prop = count / sum(count, na.rm = T),
    country_iso_alpha = reorder(country_iso_alpha, desc(prop))
  ) %>%
  arrange(desc(prop)) %>%
  mutate(
    index = row_number(),
    cumulative = cumsum(prop)
  )

# Get dataframe of labels for the plot
labels = plotdata %>%
  top_n(10, prop) %>%
  mutate(
    text = country_iso_alpha
  )

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = index, y = prop)) +
  geom_bar(stat = "identity") +
  ggrepel::geom_label_repel(data = labels, aes(label = country_iso_alpha), nudge_x = 5, size = 3, force = 2, direction = "y") +
  theme_minimal() +
  theme(axis.title.x = element_blank()) +
  ylab("Proportion of global mobile researchers")


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

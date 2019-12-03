#
# PlotProportionMobilityByCountry.R
#
# author: Dakota Murray
#
# Plot the proportion of mobile vs. nonmobile researchers by country
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

# Calculate the expected mobility, or the world proportion of org-mobile researchers
exp.org <- sum(researchers$org_mobile) / dim(researchers)[1]
exp.country <- sum(researchers$country_mobile) / dim(researchers)[1]

# Load the dataframe of all transitions, merge in other metainfo, and
# aggregate across countries and organization mobility status
flows <- read_delim(opt$flows, delim = "\t", col_types = readr::cols()) %>%
  select(-LR_main_field_no, -pub_year) %>%
  left_join(researchers, by = "cluster_id") %>%
  left_join(lookup, by = "cwts_org_no") %>%
  filter(!is.na(country_iso_alpha) & country_iso_alpha != "NULL") %>%
  tidyr::gather(key, value, org_mobile, country_mobile) %>%
  group_by(country_iso_alpha, key, value) %>%
  summarize(
    count = length(unique(cluster_id))
  )

# Remove unecessary dataframes
remove(researchers, lookup)

# construct the data for the plot
plotdata <- flows %>%
  # spread the count of org_mobile across two columns
  tidyr::spread(value, count) %>%
  rename(mobile = `TRUE`, nonmobile = `FALSE`) %>%
  mutate(
    mobile = ifelse(is.na(mobile), 0, mobile),
    total = mobile + nonmobile,
    prop = mobile / total
  ) %>%
  filter(country_iso_alpha != "NULL" & total > 100) %>%
  select(country_iso_alpha, key, prop) %>%
  tidyr::spread(key, prop) %>%
  ungroup()

# Build dataframes to label countries at the extremes
labels.country.top <- plotdata %>%
  top_n(4, country_mobile)

labels.country.bot <- plotdata %>%
  top_n(4, desc(country_mobile))

labels.org.top <- plotdata %>%
  top_n(8, org_mobile)

labels.org.bot <- plotdata %>%
  top_n(5, desc(org_mobile))

# Aggregate the labels into a single dataframe
labels <- data.table::rbindlist(list(labels.country.top, labels.country.bot, labels.org.top, labels.org.bot)) %>%
  distinct(country_iso_alpha, .keep_all = T)

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = country_mobile, y = org_mobile, group = country_iso_alpha)) +
  geom_point() +
  geom_abline() +
  ggrepel::geom_label_repel(data = labels, aes(label = country_iso_alpha), size = 3) +
  theme_minimal() +
  theme(
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold")
  ) +
  xlab("Proportion mobile across countries") +
  ylab("Proportion mobile across organizations")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

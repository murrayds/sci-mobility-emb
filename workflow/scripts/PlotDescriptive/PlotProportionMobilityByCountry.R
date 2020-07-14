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
  make_option(c("--nonmobile"), action="store", default=NA, type='character',
              help="Path to file containing nonmobile trajectories"),
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
expected.mobility <- sum(researchers$org_mobile) / dim(researchers)[1]

# Load the dataframe of all transitions, merge in other metainfo, and
# aggregate across countries and organization mobility status
flows <- read_delim(opt$flows, delim = "\t", col_types = readr::cols())

nonmobile <- read_delim(opt$nonmobile, delim = "\t", col_types = readr::cols())

# Merge with nonmobile individuals
flows <- data.table::rbindlist(list(flows, nonmobile), fill = T)

flows <- flows %>%
  select(-LR_main_field_no, -pub_year) %>%
  left_join(researchers, by = "cluster_id") %>%
  left_join(lookup, by = "cwts_org_no") %>%
  group_by(country_iso_alpha, org_mobile) %>%
  summarize(
    count = length(unique(cluster_id))
  )

print(head(flows), 10)

# Remove unecessary dataframes
remove(researchers, lookup)

# construct the data for the plot
plotdata <- flows %>%
  # spread the count of org_mobile across two columns
  tidyr::spread(org_mobile, count) %>%
  rename(mobile = `TRUE`, nonmobile = `FALSE`) %>%
  mutate(
    mobile = ifelse(is.na(mobile), 0, mobile),
    total = mobile + nonmobile,
    prop = mobile / total
  ) %>%
  filter(country_iso_alpha != "NULL" & total > 100) %>%
  arrange(desc(prop)) %>% # Arrange in descending order by proportion mobile
  ungroup() %>%
  mutate(index = row_number()) # Index used for the x-axis

print(head(plotdata, 10))
# Label the top 8 and bottom 8 bars in the chart.
# Construct as separate dataframes
labels_top <- plotdata %>%
  top_n(8, prop)

labels_bot <- plotdata %>%
  filter(!is.na(prop)) %>%
  top_n(8, rev(prop))

# Construct the plot
plot <- plotdata %>%
  ggplot(aes(x = index, y = prop)) +
    geom_bar(stat = "identity", size = 0) +
    geom_hline(yintercept = expected.mobility, linetype = "dashed") +
    ggrepel::geom_label_repel(data = labels_top, aes(label = country_iso_alpha), size = 3, direction = "y", nudge_x = 5) +
    ggrepel::geom_label_repel(data = labels_bot, aes(label = country_iso_alpha), size = 3, direction = "y", nudge_x = -5) +
    scale_x_continuous(expand = c(0, 0)) +
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      text = element_text(family = "Helvetica"),
      axis.title = element_text(size = 12, face = "bold"),
      axis.text = element_text(size = 11),
    ) +
    xlab("Rank") +
    ylab("Proportion mobile")

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

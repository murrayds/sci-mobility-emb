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
  select(cwts_org_no, country_iso_alpha)

researchers <- read_delim(opt$researchers, delim = "\t", col_types = readr::cols()) %>%
  select(cluster_id, org_mobile, city_mobile, region_mobile, country_mobile)

# Calculate the expected mobility, or the world proportion of org-mobile researchers
exp.org <- sum(researchers$org_mobile) / dim(researchers)[1]
exp.country <- sum(researchers$country_mobile) / dim(researchers)[1]

flows <- read_delim(opt$flows, delim = "\t", col_types = readr::cols()) %>%
          select(-LR_main_field_no, -pub_year)

nonmobile <- read_delim(opt$nonmobile, delim = "\t", col_types = readr::cols()) %>%
             select(-ut, -LR_main_field_no, -pub_year)

# Merge with nonmobile individuals
flows <- data.table::rbindlist(list(flows, nonmobile))

# Load the dataframe of all transitions, merge in other metainfo, and
# aggregate across countries and organization mobility status
flows <- flows %>%
  left_join(researchers, by = "cluster_id") %>%
  left_join(lookup, by = "cwts_org_no") %>%
  filter(!is.na(country_iso_alpha) & country_iso_alpha != "NULL") %>%
  tidyr::gather(key, value, org_mobile, country_mobile, region_mobile, city_mobile, ) %>%
  group_by(country_iso_alpha, key, value) %>%
  summarize(
    count = length(unique(cluster_id))
  )

# Remove unecessary dataframes
remove(researchers, lookup, nonmobile)

print(head(flows))
# construct the data for the plot
plotdata <- flows %>%
  # spread the count of org_mobile across two columns
  tidyr::spread(value, count) %>%
  rename(mobile = `TRUE`, nonmobile = `FALSE`) %>%
  mutate(
    mobile = ifelse(is.na(mobile), 0, mobile),
    total = sum(c(mobile, nonmobile), na.rm = T),
    prop = mobile / total
  ) %>%
  filter(country_iso_alpha != "NULL" & total > 200) %>%
  select(country_iso_alpha, key, prop) %>%
  tidyr::spread(key, prop) %>%
  ungroup()

print(head(plotdata))
pc <- prcomp(plotdata[ ,c(2:5)], center = TRUE, scale. = TRUE)

plotdata$pc1 <- pc$x[, 1]
plotdata$pc2 <- pc$x[, 2]

pc1.var <- round(summary(pc)$importance[2, 1], 3) * 100
pc2.var <- round(summary(pc)$importance[2, 2], 3) * 100

# Build dataframes to label countries at the extremes
labels.country.top <- plotdata %>%
  top_n(8, country_mobile)

labels.org.top <- plotdata %>%
  top_n(8, org_mobile)

labels.country.bot <- plotdata %>%
  top_n(5, desc(country_mobile))

labels.org.bot <- plotdata %>%
  top_n(5, desc(org_mobile))

labels.city.top <- plotdata %>%
  top_n(5, desc(city_mobile))

labels.region.top <- plotdata %>%
  top_n(5, desc(region_mobile))

# Aggregate the labels into a single dataframe
labels <- data.table::rbindlist(list(labels.country.top,
                                     labels.country.bot,
                                     labels.org.top,
                                     labels.org.bot,
                                     labels.city.top,
                                     labels.region.top)) %>%
  distinct(country_iso_alpha, .keep_all = T) %>%
  filter(country_iso_alpha != "PAN")


plot <- plotdata %>%
  filter(country_iso_alpha != "PAN") %>%
  ggplot(aes(x = pc1, y = pc2)) +
  geom_point() +
  ggrepel::geom_label_repel(data = labels, aes(label = country_iso_alpha), size = 3) +
  xlab(paste0("PC1: (", pc1.var, "%) - Overall mobility")) +
  ylab(paste0("PC2: (", pc2.var, "%) - Org vs. Country Mobility")) +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    text = element_text(family = "Helvetica"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11)
  )

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

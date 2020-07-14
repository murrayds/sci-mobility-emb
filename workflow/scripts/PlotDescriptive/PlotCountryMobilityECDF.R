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

# Load the flows and aggregate
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

# Build separete dataframe for the labels
labels = plotdata %>%
  top_n(5, prop) %>%
  mutate(
    text = ifelse(country_iso_alpha == "USA", "USA", paste0("+", country_iso_alpha))
  )

# Build the plot
plot <- plotdata %>%
  ggplot(aes(x = index, y = cumulative)) +
    geom_step() +
    scale_x_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30, 50), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.7, 0.8, 0.9, 1.0), expand = c(0, 0)) +
    geom_segment(x = 0, xend = 10, y = 0.80, yend = 0.80, linetype = "dashed", color = "darkgrey") +
    geom_segment(x = 10, xend = 10, y = 0, yend = 0.80, linetype = "dashed", color = "darkgrey") +
    geom_segment(x = 0, xend = 17, y = 0.90, yend = 0.90, linetype = "dashed", color = "darkgrey") +
    geom_segment(x = 17, xend = 17, y = 0.0, yend = 0.90, linetype = "dashed", color = "darkgrey") +
    geom_segment(x = 0, xend = 30, y = 0.964, yend = 0.965, linetype = "dashed", color = "darkgrey") +
    geom_segment(x = 30, xend = 30, y = 0.0, yend = 0.964, linetype = "dashed", color = "darkgrey") +
    geom_label(data = labels, aes(x = index, y = cumulative, label = text), size = 3, nudge_x = 6) +
    theme_minimal() +
    theme(
      text = element_text(family = "Helvetica"),
      axis.title = element_text(face = "bold", size = 12),
      axis.text = element_text(size = 11),
      axis.text.y = element_text(face = c(rep("plain", 9), "bold", "bold", "plain")),
      panel.grid.major = element_blank()
    ) +
    xlab("Rank") +
    ylab("Cumulative proportion")

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))

# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

#
# PlotPubsOverTime.R
#
# author: Dakota Murray
#
# Plot the numbers of publications over time
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
              help="Path to file containing career trajectories"),
  make_option(c("r", "--researchers"),, action="store", default=NA, type='character',
              help="Path to file containing researcher metadata"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the trajectories
flows <- read_delim(opt$input, delim = "\t", col_types = readr::cols())

researcher.meta <- read_delim(opt$researchers, delim = "\t", col_types = readr::cols()) %>%
  select(cluster_id, org_mobile, city_mobile, region_mobile, country_mobile)

# Get the cluster-level meta-information
flows.withmeta <- flows %>%
  left_join(researcher.meta, by = c("cluster_id"))

plotdata <- flows.withmeta %>%
  filter(pub_year < 2019) %>% # few publications in this year
  mutate(pub_year = factor(pub_year)) %>% # make pub_year a factor, makes plotting easier
  # Get researcher mobile + nonmobile counts for each year
  group_by(pub_year) %>%
  summarize(
    count = n(),
    count_org_mobile = sum(org_mobile, na.rm = T),
    count_city_mobile = sum(city_mobile, na.rm = T),
    count_region_mobile = sum(region_mobile, na.rm = T),
    count_country_mobile = sum(country_mobile, na.rm = T)
  ) %>%
  # Convert to long format
  tidyr::gather(Scale, value,
                count_org_mobile,
                count_city_mobile, count_region_mobile,
                count_country_mobile) %>%
  mutate(
    # Set order and labels of the counts
    Scale = factor(Scale,
                 levels = c("count_org_mobile", "count_city_mobile", "count_region_mobile", "count_country_mobile"),
                 labels = c("Organization", "City", "Region", "Country"))
  ) %>%
  group_by(Scale, pub_year) %>%
  summarize(
    prop = value / count
  )

# Draw the plot
plot <- plotdata %>%
  ggplot(aes(x = pub_year, y = prop, group = Scale, fill = Scale)) +
  geom_line() +
  geom_point(size = 3, shape = 21) +
  ylim(0, 1) +
  viridis::scale_fill_viridis(discrete = T) +
  guides(fill = guide_legend(ncol = 2)) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(size = 0.5),
    axis.title.x = element_blank(),
    axis.title.y = element_text(size = 12, face = "bold"),
    legend.title = element_text(size = 12, face = "bold"),
    legend.position = c(0.2, 0.85),
    legend.background = element_rect()
  ) +
  ylab("Proportion")

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

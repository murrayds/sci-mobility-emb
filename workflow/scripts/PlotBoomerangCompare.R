#
# PlotBoomerangCompare.R
#
# author: Dakota Murray
#
# Plot the comparison of the Boomerang plot between two countries
#

# Preset colors for specific countries, other defaults to grey
col_list <- list(
  "USA" = "#d35400",
  "BRA" = "#27ae60",
  "SWD" = "#8e44ad",
  "EGY" = "black"
)

# Plot dimensions
FIG_WIDTH = 3
FIG_HEIGHT = 3

library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing the factor orgs for each org"),
  make_option(c("--lookup"), action="store", default="none",
              help="Path to organization-level metadata"),
  make_option(c("--sizes"), action="store", default="none",
              help="Path to organization sizes"),
  make_option(c("--country1"), action="store", default="none",
              help="Country 1 to comapre"),
  make_option(c("--country2"), action="store", default="none",
              help="Country 2 to comapre"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregated distance file
df = readr::read_csv(opt$input, col_types = readr::cols()) %>%
  select(cwts_org_no, l2norm)

# Load the sizes and aggregate by org
sizes <- readr::read_delim(opt$sizes, delim = "\t", col_types = readr::cols()) %>%
  group_by(cwts_org_no) %>%
  summarize(size = mean(person_count))


# Load the metadata and filter to the select countries
meta <- readr::read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  filter(country_iso_alpha %in% c(opt$country1, opt$country2)) %>%
  rename(country = country_iso_name) %>%
  # rename countries to smaller, simpler versions, if necessary
  mutate(
    country = ifelse(country == "Russian Federation", "Russia", country),
    country = ifelse(country == "Korea, Republic of", "South Korea", country),
    country = ifelse(country == "Taiwan, Province of China", "Taiwan", country),
    country = ifelse(country == "Iran, Islamic Republic of", "Iran", country),
  )

# Lookup the match between the input iso alpha code and the name of the country
country_name1 = first(meta[meta$country_iso_alpha == opt$country1, ]$country)
country_name2 = first(meta[meta$country_iso_alpha == opt$country2, ]$country)

# If the two are identical, then simply use one
if (country_name1 == country_name2) {
  country_name2 = NA
}

# Lookup the colors
col1 <- ifelse(opt$country1 %in% names(col_list),
               as.character(col_list[opt$country1]),
               "grey")

col2 <- ifelse(opt$country2 %in% names(col_list),
               as.character(col_list[opt$country2]),
               "grey")

# Build the plot
plot <- df %>%
  # join metadata, filtering to select orgs in the process
  inner_join(meta, by = "cwts_org_no") %>%
  # join the sizes
  left_join(sizes, by = "cwts_org_no") %>%
  mutate(
    country = factor(country, levels = c(country_name1, country_name2))
  ) %>%
  ggplot(aes(x = size, y = l2norm, fill = country, color = country, linetype = country)) +
  stat_smooth( # Add the loess regression line
    method = "loess",
    size = 2,
    level = 0.99,
    se = T,
    alpha = 0.6
  ) +
  scale_color_manual(values = c(col1, col2)) +
  scale_fill_manual(values = c(col1, col2)) +
  scale_linetype_manual(values = c(2, 1)) +
  scale_x_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  scale_y_continuous(
    limits = c(0, 7),
    breaks = c(2, 4, 6)
  ) +
  guides(shape = F) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 14),
    axis.title.x = element_text(angle = 0, size = 16, face = "bold", vjust = 0.5),
    axis.title.y = element_text(angle = 90, size = 16, face = "bold"),
    legend.text = element_text(size = 16, face = "bold"),
    legend.position = c(0.5, 0.2),
    legend.title = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.background = element_rect(size = 0.5),
    legend.box.background = element_rect(color=NA, fill = NA)
  ) +
  annotation_logticks(sides = "b") +
  xlab("# Researchers") +
  ylab("L2 Norm")


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

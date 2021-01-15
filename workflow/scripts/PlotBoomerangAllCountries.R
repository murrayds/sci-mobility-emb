#
# PlotBoomerangAllCountries.R
#
# author: Dakota Murray
#
# Plot the boomerang pattern across many countries
#

# Plot dimensions
FIG_WIDTH = 7
FIG_HEIGHT = 9

NUM_COUNTRIES = 30

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
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the aggregated distance file
df = readr::read_csv(opt$input, col_types = readr::cols()) %>%
  select(cwts_org_no, l2norm)

# Load the sizes and aggregate by org
sizes <- readr::read_delim(opt$sizes, delim = "\t", col_types = readr::cols())

# Load the metadata and filter to the select countries
meta <- readr::read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  rename(country = country_iso_name) %>%
  # rename countries to smaller, simpler versions, if necessary
  mutate(
    country = ifelse(country == "Russian Federation", "Russia", country),
    country = ifelse(country == "Korea, Republic of", "South Korea", country),
    country = ifelse(country == "Taiwan, Province of China", "Taiwan", country),
    country = ifelse(country == "Iran, Islamic Republic of", "Iran", country),
  )

df <- df %>%
  # join metadata, filtering to select orgs in the process
  inner_join(meta, by = "cwts_org_no") %>%
  # join the sizes
  left_join(sizes, by = "cwts_org_no") %>%

print(head(df))
# Get the countries to plot
selected <- (df %>%
  group_by(country) %>%
  summarize(total = sum(size)) %>%
  top_n(30, total))$country


plot <- df %>%
  filter(!is.na(l2norm)) %>%
  filter(country %in% c(selected)) %>%
  ggplot(aes(x = size, y = l2norm)) +
  geom_point(alpha = 0.2) +
  stat_smooth(
    method = "loess",
    size = 1,
    se = T,
    level = 0.99,
    color = "#2980b9",
    fill = "#2980b9",
    alpha = 0.4,
  ) +
  scale_x_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  scale_y_continuous(
    limits = c(0, 7),
    breaks = c(2, 4, 6)
  ) +
  facet_wrap(~country, ncol = 5) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 14),
    axis.title.x = element_text(angle = 0, size = 16, face = "bold", vjust = 0.5),
    axis.title.y = element_text(angle = 90, size = 16, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.background = element_rect(size = 0.5),
    strip.text = element_text(face = "bold")
  ) +
  annotation_logticks(sides = "b") +
  xlab("# Researchers") +
  ylab("L2 Norm")


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

#
# PlotTimesVsImpactRank.R
#
# author: Dakota Murray
#
# Plot the comparison between the ranking derived from the simularity
# projection and the standard university ranking
#

# Plot dimensions
FIG_WIDTH = 6
FIG_HEIGHT = 6

library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--semaxis"), action="store", default=NA, type='character',
              help="Path to file containing semaxis ranking"),
  make_option(c("--impact"), action="store", default=NA, type='character',
              help="Path to file containing times ranking"),
  make_option(c("--types"), action="store", default=NA, type='character',
              help="Path to file containing org types"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("--sizes"), action="store", default="none", type='character',
              help="Path to organization sizes"),
  make_option(c("--sector"), action="store", default=NA, type='character',
              help="Type of organization to limit to, Teaching, Institute, or Government"),
  make_option(c("--threshold"), action="store", default=NA, type='integer',
              help="Threshold of size of organization to limit to"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Semaxis data
semaxis <- read_csv(opt$semaxis, col_types = cols())

# Impact data from the Leiden database
impact <- read_delim(opt$impact, delim = "\t", col_types = cols())

# Organization types
org_types <- read_csv(opt$types, col_types = cols())

# Organization lookup table, metadata
lookup <- read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  filter(country_iso_alpha == "USA") # select only the specified country

# Information on the sizes of organizations
sizes <- readr::read_delim(opt$sizes, delim = "\t", col_types = readr::cols())

# Set the threshold based on the sector
if (opt$sector == "Teaching") {
  threshold <- 10
} else {
  threshold <- 50
}

ranks <- impact %>%
  # Make sure the impact is set to a numeric
  mutate(impact = as.numeric(mncs)) %>%
  # Join the metadata
  left_join(lookup, by = "cwts_org_no") %>%
  filter(country_iso_alpha == "USA") %>%
  left_join(org_types, by = "org_type") %>%
  left_join(sizes, by = "cwts_org_no") %>%
  left_join(semaxis, by = "cwts_org_no") %>%
  filter(size >= threshold) %>%
  filter(org_type_simplified == opt$sector) %>%
  filter(!is.na(sim) & !is.na(impact)) %>%
  # Get the rank based off of their citation impact (mean normalized citation score)
  arrange(desc(impact)) %>%
  mutate(impact_rank = row_number()) %>%
  # Get the rank based off of their SemAxis position
  arrange((sim)) %>%
  mutate(semaxis_rank = row_number())

# Define which organizations will be labeled
labels1 <- ranks %>%
  mutate(diff = abs(impact_rank - semaxis_rank)) %>%
  top_n(4, diff) %>%
  select(-diff)
  # Wrap the text when its too long

# Also get the labels for those top-ranked places
labels2 <- ranks %>%
  top_n(-2, impact_rank)

# Also get the labels for those top-ranked places
labels3 <- ranks %>%
  top_n(-2, semaxis_rank)

# Form the labels into a single dataframe
labels <- data.table::rbindlist(list(labels1, labels2, labels3)) %>%
  mutate(
    label = gsub('University', 'Univ', full_name),
    label = gsub('Institute', 'Inst', full_name),
    label = gsub('National', 'Nat', full_name),
    label = gsub('(.{1,24})(\\s|$)', '\\1\n', label),
    label = trimws(label)
  ) %>%
  distinct()

# The title of the plot
axis.title <- "MNCS Ranking"

# Get the spearman correlation between the SemAxis-derived ranking
# and the formal univeristy ranking. The estimate will be shown
# on the plot
cor <- cor.test( ~ impact_rank + semaxis_rank,
                data = ranks,
                method = "spearman",
                continuity = FALSE,
                conf.level = 0.95)

max_val <- max(c(ranks$impact_rank, ranks$semaxis_rank))

# Build the plot
plot <- ranks %>%
  ggplot(aes(x = semaxis_rank, y = impact_rank)) +
  geom_abline() +
  geom_point(size = 3.5, stroke = 0.5) +
  ggrepel::geom_label_repel(
    data = labels,
    force = 20,
    min.segment.length = 0.1,
    alpha = 0.9,
    aes(label = label),
    size = 3.5) +
  # Add a fake top axis title, just to ensure that its the same size as the 2d fig
  scale_x_continuous(limits = c(0, max_val), sec.axis = dup_axis(name = "")) +
  scale_y_continuous(limits = c(0, max_val * 1.05)) +
  guides(shape = F) +
  theme_minimal() +
  theme(
    text = element_text(size = 16, family = "Helvetica"),
    axis.text.x.top = element_blank(),
    #axis.title = element_text(size = 16),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(size = 0.5, fill = NA)
  ) +
  # Add the Spearman's Rho to the plot
  annotate("text",
           label = latex2exp::TeX(paste("Spearman's $\\rho = ", round(cor$estimate, 2))),
           size = 7,
           x = 0.025 * max(ranks$semaxis_rank),
           y = 1.04 * max(ranks$impact_rank),
           hjust = 0, vjust = 1,
           fontface = 2) +
  xlab("Embedding rank") +
  ylab(axis.title)


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

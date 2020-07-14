#
# PlotPrestigeSimVsRank.R
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
  make_option(c("--times"), action="store", default=NA, type='character',
              help="Path to file containing times Ranking"),
  make_option(c("--leiden"), action="store", default=NA, type='character',
              help="Path to file containing Leiden Ranking"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

times <- read_csv(opt$times, col_types = cols())
leiden <- read_csv(opt$leiden, col_types = cols())

# Begin by loading the formal univeristy ranking
ranks <- read_delim(opt$lookup, col_types = cols(), delim = "\t") %>%
  filter(country_iso_alpha == "USA") %>% # Limit to USA universities
  left_join(times, by = c("cwts_org_no")) %>%
  inner_join(leiden, by = c("cwts_org_no")) %>%
  select(full_name, cwts_org_no, total_score, impact_frac_mncs) %>%
  filter(!is.na(total_score & !is.na(impact_frac_mncs))) %>%
  arrange(desc(total_score)) %>%
  mutate(
    times_rank = row_number()
  ) %>%
  arrange(desc(impact_frac_mncs)) %>%
  mutate(
    leiden_rank = row_number()
  )

print(dim(ranks))
print(head(ranks))



# Define which organizations will be labeled
labels <- ranks %>%
  mutate(diff = abs(leiden_rank - times_rank)) %>%
  top_n(12, diff) %>%
  # Wrap the text when its too long
  mutate(
    label = gsub('University', 'Univ', full_name),
    label = gsub('(.{1,24})(\\s|$)', '\\1\n', label),
    label = trimws(label)
  )

# Get the spearman correlation between the SemAxis-derived ranking
# and the formal univeristy ranking. The estimate will be shown
# on the plot
cor <- cor.test( ~ leiden_rank + times_rank,
                data = ranks,
                method = "spearman",
                continuity = FALSE,
                conf.level = 0.95)

max_val <- max(c(ranks$leiden_rank, ranks$times_rank))

# Build the plot
plot <- ranks %>%
  ggplot(aes(x = leiden_rank, y = times_rank)) +
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
  scale_y_continuous(limits = c(0, max_val + 10)) +
  guides(shape = F) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    axis.text.x.top = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
  ) +
  # Add the Spearman's Rho to the plot
  annotate("text", x = 34, y = 132,
           label = paste("Spearman's Rho = ", round(cor$estimate, 2)),
           size = 7,
           fontface = 2) +
  ylab("Times Rank") +
  xlab("Leiden Rank")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

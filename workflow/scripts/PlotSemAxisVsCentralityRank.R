#
# PlotTimesVsCentralityRank.R
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
  make_option(c("--centrality"), action="store", default=NA, type='character',
              help="Path to file containing centrality ranking"),
  make_option(c("--semaxis"), action="store", default=NA, type='character',
              help="Path to file containing semaxis ranking"),
  make_option(c("--times"), action="store", default=NA, type='character',
              help="Path to file containing times ranking"),
  make_option(c("--measure"), action="store", default=NA, type='character',
              help="Name of the centrality measure to use for the rank"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

semaxis <- read_csv(opt$semaxis, col_types = cols())
centrality <- read_csv(opt$centrality, col_types = cols())

# Load the times rankings also, as these are used to filter US orgs
times <- read_csv(opt$times, col_types = cols())

# Begin by loading the formal univeristy ranking
ranks <- read_delim(opt$lookup, col_types = cols(), delim = "\t") %>%
  filter(country_iso_alpha == "USA") %>% # Limit to USA universities
  inner_join(times, by = c("cwts_org_no")) %>%
  left_join(semaxis, by = c("cwts_org_no")) %>%
  left_join(centrality, by = c("cwts_org_no")) %>%
  rename(centrality = opt$measure) %>%
  select(full_name, cwts_org_no, sim, centrality) %>%
  filter(!is.na(sim) & !is.na(centrality)) %>%
  arrange(desc(centrality)) %>%
  mutate(
    centrality_rank = row_number()
  ) %>%
  arrange(sim) %>%
  mutate(semaxis_rank = row_number())

# Define which organizations will be labeled
labels <- ranks %>%
  mutate(diff = abs(centrality_rank - semaxis_rank)) %>%
  top_n(10, diff) %>%
  # Wrap the text when its too long
  mutate(
    label = gsub('University', 'Univ', full_name),
    label = gsub('(.{1,24})(\\s|$)', '\\1\n', label),
    label = trimws(label)
  )


axis.title <- ifelse(opt$measure == "eigen", "Eigenvector Centrality Rank",
                     "Degree Centrality Rank")



# Get the spearman correlation between the SemAxis-derived ranking
# and the formal univeristy ranking. The estimate will be shown
# on the plot
cor <- cor.test( ~ centrality_rank + semaxis_rank,
                data = ranks,
                method = "spearman",
                continuity = FALSE,
                conf.level = 0.95)

max_val <- max(c(ranks$leiden_rank, ranks$semaxis_rank))

# Build the plot
plot <- ranks %>%
  ggplot(aes(x = semaxis_rank, y = centrality_rank)) +
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
  scale_y_continuous(limits = c(0, max_val + 15)) +
  guides(shape = F) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    axis.text.x.top = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
  ) +
  # Add the Spearman's Rho to the plot
  annotate("text", x = 35, y = 155,
           label = latex2exp::TeX(paste("Spearman's $\\rho = ", round(cor$estimate, 2))),
           size = 7,
           fontface = 2) +
  xlab("Embedding rank") +
  ylab(axis.title)



# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

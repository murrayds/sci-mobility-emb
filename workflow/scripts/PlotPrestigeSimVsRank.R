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
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing the SemAxis similarities"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("--ranks"), action="store", default=NA, type='character',
              help="Path to file ranking data, either times or leiden"),
  make_option(c("--norgs"), action="store", default=NA, type='integer',
            help="The number of organizations used to form the mean vector
                  for the SemAxis poles"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Begin by loading the formal univeristy ranking
ranks <- read_csv(opt$ranks, col_types = cols())

# Select the correct ranking variable based on the
# source of the ranking, Times or Leiden
if (grepl("times", opt$ranks, fixed = T)) {
  ranks <- ranks %>%
    rename(score = total_score)
  axis_title <- "Times Rank"
} else if (grepl("leiden", opt$ranks, fixed = T)) {
  ranks <- ranks %>%
    rename(score = impact_frac_mncs)
  axis_title <- "Leiden Rank"
}

# Load the organizational lookup information, filter to only US
lookup_usa <- read_delim(opt$lookup, delim = "\t", col_types = cols()) %>%
  filter(country_iso_alpha == "USA")

# Construct a new ranks dataframe that includes metadata and
# numeric rank derived from the scores
ranks <- ranks %>%
  inner_join(lookup_usa, by = "cwts_org_no") %>%
  arrange(desc(score)) %>%
  mutate(
    rank = row_number()
  )

# Load the similarity information
sims <- read_csv(opt$input, col_types = cols()) %>%
  inner_join(ranks, by = "cwts_org_no")

# Enforce orientation, high-ranked organizations should have high similarities
# than low-ranked ones. If not, then reverse
if (sims[which.min(sims$rank), "sim"] < sims[which.max(sims$rank), "sim"]) {
  sims <- sims %>% mutate(sim = -sim)
}

# Assign a rank based on the similarity metric
sims <- sims %>%
  arrange(desc(sim)) %>%
  mutate(
    sim_rank = row_number()
  ) %>%
  # Assign a variable indicating whether the organization was
  # included in the mean-vector used in the SemAxis poles
  mutate(included = ifelse(rank <= opt$norgs | rank >= max(rank) - opt$norgs,
                           "included", "not"))

max_val <- max(sims$rank)

sims <- sims %>%
  mutate(
    rank = max_val - rank,
    sim_rank = max_val - sim_rank
  )

# Define which organizations will be labeled
labels <- sims %>%
  mutate(
    diff = abs(sim_rank - rank)
  ) %>%
  filter(rank < 130 & sim_rank < 130) %>%
  top_n(8, diff) %>%
  # Wrap the text when its too long
  mutate(
    label = gsub('University', 'Univ', full_name),
    label = gsub('(.{1,24})(\\s|$)', '\\1\n', label),
    label = trimws(label),
    #rank = max_val - rank
  )

# Get the spearman correlation between the SemAxis-derived ranking
# and the formal univeristy ranking. The estimate will be shown
# on the plot
cor <- cor.test( ~ sim_rank + rank,
                data = sims,
                method = "spearman",
                continuity = FALSE,
                conf.level = 0.95)

print(min(sims$sim_rank))
print(max_val)

# Build the plot
plot <- sims %>%
  ggplot(aes(x = sim_rank, y = rank, shape = included)) +
  geom_rect(
            xmin = 1, xmax = max_val, ymin = 1, ymax = opt$norgs,
            fill = "lightgrey"
          ) +
  geom_rect(
            xmin = 1, xmax = max_val,
            ymin = max_val - opt$norgs, ymax = max_val,
            fill = "lightgrey"
          ) +
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
  scale_x_continuous(
    limits = c(0, max_val + 1),
    breaks = c(1, 50, 100, max_val),
    labels = c(as.character(max_val), "100", "50", "1"),
    sec.axis = dup_axis(name = ""),
    expand = c(0, 1)
  ) +
  scale_y_continuous(
    limits = c(0, max_val + 5),
    breaks = c(1, 50, 100, max_val),
    labels = c(as.character(max_val), "100", "50", "1"),
    expand = c(0, 1)
  ) +
  scale_shape_manual(values = c(1, 16)) +
  guides(shape = F) +
  theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Helvetica"),
    axis.text.x.top = element_blank(),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.minor = element_blank(),
  ) +
  # Add the Spearman's Rho to the plot
  annotate("text", x = 40, y = 145,
           label = latex2exp::TeX(paste("Spearman's $\\rho = ", round(cor$estimate, 2))),
           size = 7,
           fontface = 2) +
  ylab(axis_title) +
  xlab("SemAxis Rank")


# p <- egg::set_panel_size(plot,
#                          width  = unit(FIG_WIDTH, "in"),
#                          height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

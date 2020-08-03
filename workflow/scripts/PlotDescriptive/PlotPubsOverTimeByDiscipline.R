#
# PlotPubsOverTimeByDiscipline.R
#
# author: Dakota Murray
#
# Plot the numbers of publications over time, by discipline, for only mobile scholars
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
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the trajectories
flows <- read_delim(opt$input, delim = "\t", col_types = readr::cols())

# Create a dataframe of publication counts for mobile scholars, by discipline.
plotdata <- flows %>%
    filter(pub_year < 2019) %>%
    mutate(pub_year = factor(pub_year),
           Discipline = factor(LR_main_field_no),
           Discipline = recode(Discipline,
                               `1` = "SS & HUM",
                               `2` = "BIO & HEALTH",
                               `3` = "PHYS & ENGR",
                               `4` = "LIFE & EARTH",
                               `5` = "MATH & CS"),
           Discipline = factor(Discipline, levels = c("BIO & HEALTH", "PHYS & ENGR", "LIFE & EARTH", "SS & HUM", "MATH & CS"))
           ) %>%
    group_by(Discipline, pub_year) %>%
    summarize(count = n())

# Draw the plot
plot <- plotdata %>%
  ggplot(aes(x = pub_year, y = count, group = Discipline, fill = Discipline)) +
    geom_line() +
    geom_point(size = 3, shape = 21) +
    expand_limits(y = 0) + # Make sure that y=axis stretches to 0
    scale_y_continuous(limits = c(0, 1500000),
                       breaks = c(0, 500000, 1000000, 1500000),
                       labels = c("0", "500,000", "1,000,000", "1,500,000")) +
    viridis::scale_fill_viridis(discrete = T, option = "A") +
    theme_minimal() +
    theme(
      text = element_text(size = 12, family = "Helvetica"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      panel.background = element_rect(size = 0.5),
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12, face = "bold"),
      legend.position = c(0.20, 0.81),
      legend.background = element_rect()
    ) +
    ylab("Count")

p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))
# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 1, height = FIG_HEIGHT + 1)

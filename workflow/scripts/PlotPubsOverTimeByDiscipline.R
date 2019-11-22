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
    group_by(pub_year) %>%
    mutate(count = n()) %>%
    group_by(pub_year, Discipline) %>%
    summarize(
      prop = n() / first(count)
    )

# Draw the plot
plot <- plotdata %>%
  ggplot(aes(x = pub_year, y = prop, group = Discipline, fill = Discipline)) +
    geom_line() +
    geom_point(size = 3, shape = 21) +
    ylim(0, 1) +
    viridis::scale_fill_viridis(discrete = T, option = "A") +
    theme_minimal() +
    theme(
      axis.title.x = element_blank(),
      legend.text = element_text(size = 11),
      legend.title = element_text(size = 12, face = "bold"),
      legend.position = c(0.20, 0.75),
      legend.background = element_rect()
    ) +
    ylab("Proportion")

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

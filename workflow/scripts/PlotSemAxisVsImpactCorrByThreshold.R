#
# PlotSemAxisVsImpactCorrByThreshold.R
#
# author: Dakota Murray
#
# Plot the comparison between the ranking derived from the simularity
# projection and the standard university ranking
#
# Plot dimensions
FIG_WIDTH = 12
FIG_HEIGHT = 4

# The thresholds to plot
thresholds <- c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150)

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

base_data <- impact %>%
  # Make sure the impact is set to a numeric
  mutate(impact = as.numeric(mncs)) %>%
  # Join the metadata
  left_join(lookup, by = "cwts_org_no") %>%
  filter(country_iso_alpha == "USA") %>%
  left_join(org_types, by = "org_type") %>%
  left_join(sizes, by = "cwts_org_no") %>%
  left_join(semaxis, by = "cwts_org_no")

print(head(base_data$sim))

# Calculate the correlation across sectors and thresholds
all.sectors <- data.table::rbindlist(lapply(c("Institute", "Government", "Teaching"), function(sector) {
  for_sector <- data.table::rbindlist(lapply(thresholds, function(x) {
    df <- base_data %>%
      filter(org_type_simplified == sector) %>%
      filter(size > x) %>%
      arrange(desc(mncs)) %>%
      mutate(impact_rank = row_number()) %>%
      #left_join(semaxis, by = "cwts_org_no") %>%
      arrange(desc(sim)) %>%
      mutate(semaxis_rank = row_number())

    if (dim(df)[1] > 10) {
      test <- cor.test( ~ impact_rank + semaxis_rank,
              data = df,
              method = "spearman",
              continuity = FALSE,
              conf.level = 0.95)
      stat = test$estimate[[1]]
    } else {
      stat = NA
    }

    return(data.frame(statistic = stat, threshold = x, sector = sector, n = dim(df)[1]))
  }))

}))

print(head(all.sectors))
# Format the plot data
plotdata <- all.sectors %>%
  mutate(statistic = abs(statistic)) %>%
  mutate(
    sector = factor(sector, levels = c("Teaching", "Institute", "Government")),
    sector = factor(sector,
                    labels = c("Regional & Liberal\nArts Colleges",
                               "Research Institutes",
                               "Government Organizations"))
)

# Construct the plot
plot <- plotdata %>%
  ggplot(aes(x = threshold, y = statistic)) +
  geom_point() +
  geom_line() +
  geom_text(data = plotdata %>% filter(threshold %in% c(0, 50, 100)),
            aes(label = paste0("n=", n), x = threshold, y = abs(statistic)),
            vjust = -0.5, hjust = -0.25
  ) +
  scale_x_continuous(limits = c(0, NA)) +
  facet_wrap(~sector) +
  theme_minimal() +
  theme(
    text = element_text(family = 'Helvetica', size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 12),
    panel.border = element_rect(size = 0.5, fill = NA),
    panel.margin = unit(2, "lines"),
  ) +
  xlab("# yearly unique publishing authors threshold") +
  ylab(latex2exp::TeX("Spearman's $\\rho"))


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

#
# Plot1DSemAxis.R
#
# author: Dakota Murray
#
# Visualizes a subset of organizations along an axis
#

# Plot dimensions
FIG_WIDTH = 8
FIG_HEIGHT = 6

NOT_HIGHLIGHTED_ALPHA = 0.9


STATES_TO_PLOT <- c("Indiana", "Ohio", "Connecticut", "New York", "Arizona", "California", "Massachusetts", "Florida")
STATE_COLORS <- c("#7fc97f", "#beaed4", "#fdc086", "#ffff99", "#386cb0", "#f0027f", "#bf5b17", "#666666")


library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("a1", "--axis1"), action="store", default=NA, type="character",
              help="Path to input file containing SemAxis projection"),
  make_option(c("a2", "--axis2"), action="store", default=NA, type="character",
              help="Path to input file containing SemAxis projection"),
  make_option(c("l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("--labels"), action="store", default=NA, type='character',
              help="Path to file org labels"),
  make_option(c("c", "--country"), action="store", default=NA, type='character',
              help="Country code to filter to, all others are removed"),
  make_option(c("e1", "--endleft"), action="store", default=NA, type='character',
              help="Label on the low-end of the axis"),
  make_option(c("e2", "--endright"), action="store", default=NA, type='character',
              help="Label on the high-end of the axis"),
  make_option(c("e3", "--endbot"), action="store", default=NA, type='character',
              help="Label on the low-end of the axis"),
  make_option(c("e4", "--endtop"), action="store", default=NA, type='character',
            help="Label on the high-end of the axis"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load organization meta-info
lookup <- read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  filter(country_iso_alpha == opt$country) %>% # select only the specified country
  filter(org_type_code == "U") %>% # select only universities
  select(cwts_org_no, country_iso_alpha, region)


axis2 <- read_csv(opt$axis2, col_types = readr::cols())

# Load the axis data and filter to only specified countries
sims <- read_csv(opt$axis1, col_types = readr::cols()) %>%
  inner_join(lookup, by = "cwts_org_no") %>%
  inner_join(axis2, by = "cwts_org_no")

# Enforce orientation. Not sure how we can automate this, so we will
# likely have to create separate rules for each kind of axis we choose
# I am defining these rules here based on what we know about the data already, namely
# which regions have more and less elite, or which are more or near the coasts.
if (any(c(opt$endleft, opt$endright) %in% c("Massachusetts", "California"))) {
  cali_avg <- mean(subset(sims, region == "California")$sim.x)
  mass_avg <- mean(subset(sims, region == "Massachusetts")$sim.x)
  if (cali_avg > mass_avg) {
    sims$sim.x <- -sims$sim.x
  }
}

if (any(c(opt$endbot, opt$endtop) %in% c("Elite", "Non-elite"))) {
  ny_avg <- mean(subset(sims, region == "New York")$sim.y)
  bama_avg <- mean(subset(sims, region == "Alabama")$sim.y)
  if (bama_avg > ny_avg) {
    sims$sim.y <- -sims$sim.y
  }
}

labels <- readr::read_csv(opt$labels, col_types = readr::cols()) %>%
    inner_join(sims, by = c("cwts_org_no"))

x_ceiling <- ceiling(max(abs(sims$sim.x)) * 100) / 100
y_ceiling <- ceiling(max(abs(sims$sim.y)) * 100) / 100
label_size <- max(nchar(c(opt$endlow, opt$endhigh)))

plot <- sims %>%
  mutate(
    state = ifelse(region %in% STATES_TO_PLOT, region, "Others"),
    state = factor(state, levels = c(sort(STATES_TO_PLOT), "Others"))
  ) %>%
  filter(state != "Others") %>%
  ggplot(aes(x = sim.x, y = sim.y, fill = state)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3.5, shape = 21) +
  ggrepel::geom_label_repel(
    data = labels,
    inherit.aes = F,
    aes(x = sim.x, y = sim.y, label = short_name)
  ) +
  scale_fill_manual(name = "Region", values = STATE_COLORS) +
  scale_x_continuous(
    limits = c(-x_ceiling, x_ceiling),
    name = opt$endbot,
    sec.axis = dup_axis(name = opt$endtop)
  ) +
  scale_y_continuous(
    limits = c(-y_ceiling, y_ceiling),
    name = opt$endleft,
    sec.axis = dup_axis(name = opt$endright)
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 11),
    axis.title.x = element_text(angle = 0, size = 12, face = "bold", vjust = 0.5),
    axis.title.x.top = element_text(angle = 0, size = 12, face = "bold", vjust = 0.5),
    axis.title.y = element_text(angle = 0, size = 12, face = "bold", vjust = 0.5),
    axis.title.y.right = element_text(angle = 0, size = 12, face = "bold", vjust = 0.5),
    legend.text = element_text(size = 12),
    legend.title = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )


# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

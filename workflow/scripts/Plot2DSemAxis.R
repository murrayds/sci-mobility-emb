#
# Plot2DSemAxis.R
#
# author: Dakota Murray
#
# Visualizes a subset of organizations along an axis, overall.
# Currently, assumes that only the US is being plotted
#

# Plot dimensions
FIG_WIDTH = 6
FIG_HEIGHT = 6

NOT_HIGHLIGHTED_ALPHA = 0.9

MASS_LABEL = "Massachusetts"
CALI_LABEL = "California"
TOP_LABEL = "Elite"
BOT_LABEL = "Non elite"

STATES_TO_PLOT <- c("Connecticut", "New York", "Arizona", "California", "Massachusetts", "Florida")
STATE_COLORS <- c("#7fc97f", "#beaed4", "#fdc086", "#ffff99", "#386cb0", "#f0027f")


ORG_TYPES = c("Government", "Institute", "Teaching")

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
  make_option(c("--overall"), action="store_true", default=FALSE, type='character',
              help="If set, plot overall"),
  make_option(c("--state"), action="store", default=NA, type='character',
              help="Name of the state to highlight"),
  make_option(c("--types"), action="store", default=NA, type='character',
              help="Path to file containing org types"),
  make_option(c("--sector"), action="store", default=NA, type='character',
              help="Name of sector: Teaching, Government, or Institute"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load organization meta-info
lookup <- read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  filter(country_iso_alpha == "USA") %>% # select only the specified country
  select(cwts_org_no, country_iso_alpha, region, org_type_code, org_type)

axis2 <- read_csv(opt$axis2, col_types = readr::cols())

# Load the axis data and filter to only specified countries
sims <- read_csv(opt$axis1, col_types = readr::cols()) %>%
  inner_join(lookup, by = "cwts_org_no") %>%
  inner_join(axis2, by = "cwts_org_no")

# Enforce orientation. Not sure how we can automate this, so we will
# likely have to create separate rules for each kind of axis we choose
# I am defining these rules here based on what we know about the data already, namely
# which regions have more and less elite, or which are more or near the coasts.
cali_avg <- mean(subset(sims, region == "California")$sim.x)
mass_avg <- mean(subset(sims, region == "Massachusetts")$sim.x)
if (cali_avg > mass_avg) {
  sims$sim.x <- -sims$sim.x
}

ny_avg <- mean(subset(sims, region == "New York")$sim.y)
bama_avg <- mean(subset(sims, region == "Alabama")$sim.y)
if (bama_avg > ny_avg) {
  sims$sim.y <- -sims$sim.y
}


# If plotting overall, set proper filter variable,
if (opt$overall == TRUE) {
  plotdata <- sims %>%
    filter(org_type_code == "U") %>% # Only univeristies
    mutate(
      highlight = ifelse(region %in% STATES_TO_PLOT, region, "Others"),
      highlight = factor(highlight, levels = c(sort(STATES_TO_PLOT), "Others"))
    )
} else {
  plotdata <- sims
  pointcolor <- "#f39c12" # default pointcolor

  ###
  # If sector provided
  ###
  if (!is.na(opt$sector)) {
    org_types <- read_csv(opt$types, col_types = cols())
    plotdata <- plotdata %>%
      left_join(org_types, by = "org_type") %>%
      filter(org_type_simplified == opt$sector | org_type_code == "U") %>%
      mutate(
        highlight = ifelse(org_type_simplified %in% ORG_TYPES, org_type_simplified, "Others"),
        highlight = factor(highlight, levels = c(opt$sector, "Others"))
      )

    # If only sector provided, color by sector
    if (is.na(opt$state)) {
      if (opt$sector == "Government") {
        pointcolor <- "#16a085"
      } else if (opt$sector == "Institute") {
        pointcolor <- "#2980b9"
      } else if (opt$sector == "Teaching"){
        pointcolor <- "#8e44ad"
      } else {
        pointcolor <- "#2980b9"
      }
    } # end color selection
  } else { # Otherwise, if no sector provided, default filter to uni
    plotdata <- plotdata %>%
      filter(org_type_code == "U")
  }
  ###
  # If state is provided...
  ###
  if (!is.na(opt$state)) {
    target_state = gsub("_", " ", opt$state, fixed = T)
    plotdata <- plotdata %>%
      mutate(
        highlight = ifelse(region == target_state, region, "Others"),
        highlight = factor(highlight, levels = c(target_state, "Others"))
      )

    # If no sector provided, color by state
    if (is.na(opt$sector)) {
      if (opt$state %in% c("California", "Arizona", "Washington")) {
        pointcolor <- "#FF9800"
      } else if (opt$state %in% c("Massachusetts", "Connecticut", "New_York", "Pennsylvania")) {
        pointcolor <- "#795548"
      } else if (opt$state %in% c("Texas", "Florida")) {
        pointcolor <- "#FF5722"
      } else {
        pointcolor <- "#f39c12"
      } # end color selection
    }
  } # end if State is not NA
} # End else

# If there are only a few labels, take all of them. Otherwise, sample
most_mass <- (plotdata %>% filter(highlight != "Others") %>% top_n(3, sim.x))$cwts_org_no
most_cali <- (plotdata %>% filter(highlight != "Others") %>% top_n(-3, sim.x))$cwts_org_no

most_elite <- (plotdata %>% filter(highlight != "Others") %>% top_n(5, sim.y))$cwts_org_no
least_elite <- (plotdata %>% filter(highlight != "Others") %>% top_n(-3, sim.y))$cwts_org_no

plot_labs <- data.frame(cwts_org_no = c(most_mass,
                                        most_cali,
                                        most_elite,
                                        least_elite))

labels <- readr::read_csv(opt$labels, col_types = readr::cols()) %>%
    inner_join(sims, by = c("cwts_org_no")) %>%
    inner_join(plot_labs, by = "cwts_org_no") %>%
    distinct(cwts_org_no, .keep_all = T)


# Plot dimensions and label sizes

unis <- sims %>% filter(org_type_code == "U")
x_ceiling <- ceiling(max(unis$sim.x) * 50) / 50
x_floor <- floor(min(unis$sim.x) * 50) / 50
y_ceiling <- ceiling(max(unis$sim.y) * 50) / 50
y_floor <- floor(min(unis$sim.y) * 50) / 50

plot <- plotdata %>%
  ggplot() +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(aes(x = sim.x, y = sim.y),
             size = 3.5,
             shape = 16,
             fill = "lightgrey",
             alpha = 0.1,
             data = subset(plotdata, highlight == "Others")
           ) +
  geom_point(aes(x = sim.x, y = sim.y, fill = highlight),
             size = 3.5,
             shape = 21,
             alpha = 1.0,
             data = subset(plotdata, highlight != "Others")
           ) +
  ggrepel::geom_label_repel(
    data = labels,
    size = 4,
    min.segment.length = 0.1,
    inherit.aes = F,
    aes(x = sim.x, y = sim.y, label = short_name)
  ) +
  scale_x_continuous(
    limits = c(x_floor, x_ceiling),
    name = BOT_LABEL,
    sec.axis = dup_axis(name = TOP_LABEL)
  ) +
  scale_y_continuous(
    limits = c(y_floor, y_ceiling),
    name = CALI_LABEL,
    sec.axis = dup_axis(name = MASS_LABEL)
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    axis.title.x = element_text(angle = 0, size = 14, face = "bold", vjust = 0.5),
    axis.title.x.top = element_text(angle = 0, size = 14, face = "bold", vjust = 0.5),
    axis.text.x.top = element_blank(),
    axis.title.y = element_text(angle = 90, size = 14, face = "bold"),
    axis.title.y.right = element_text(angle = 90, size = 14, face = "bold"),
    axis.text.y.right = element_blank(),
    legend.text = element_text(size = 12),
    legend.title = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = c(0.82, 0.2),
    legend.box.background = element_rect(color="black", size=0.5, fill = "white")
  )


if (opt$overall) {
  plot <- plot +
    scale_fill_manual(name = "Region", values = STATE_COLORS)
} else {
  plot <- plot +
    guides(fill = F) + # remove the fill, only 1 value
    scale_fill_manual(name = "Region", values = pointcolor)

  if (is.na(opt$sector) & !is.na(opt$state)) {
    plotlabel <- target_state
  } else if (!is.na(opt$sector) & is.na(opt$state)) {
    plotlabel <- opt$sector
  }

  plot <- plot +
    annotate(geom = "text",
             x = 0.28,
             y = -0.4,
             label = plotlabel,
             size = 7,
             fontface = 2
           )
}

# Save the plot
ggsave(opt$output, plot, width = FIG_WIDTH, height = FIG_HEIGHT)

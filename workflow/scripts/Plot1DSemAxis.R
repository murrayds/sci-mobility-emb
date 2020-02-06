#
# Plot1DSemAxis.R
#
# author: Dakota Murray
#
# Visualizes a subset of organizations along an axis
#

# Plot dimensions
FIG_WIDTH = 3
FIG_HEIGHT = 1

NOT_HIGHLIGHTED_ALPHA = 0.9

PLACE1_COLOR = "#c0392b"
PLACE2_COLOR = "#2980b9"

library(readr)
library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("i", "--input"), action="store", default=NA, type="character",
              help="Path to input file containing SemAxis projection"),
  make_option(c("l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organizational metadata"),
  make_option(c("c", "--country"), action="store", default=NA, type='character',
              help="Country code to filter to, all others are removed"),
  make_option(c("e1", "--endlow"), action="store", default=NA, type='character',
              help="Label on the low-end of the axis"),
  make_option(c("e2", "--endhigh"), action="store", default=NA, type='character',
              help="Label on the high-end of the axis"),
  make_option(c("p1", "--place1"), action="store", default=NA, type='character',
              help="Name of region to highlight"),
  make_option(c("p1code", "--place1code"), action="store", default=NA, type='character',
              help="Name of region to highlight"),
  make_option(c("p1", "--place2"), action="store", default=NA, type='character',
              help="Name of region to highlight"),
  make_option(c("p2code", "--place2code"), action="store", default=NA, type='character',
              help="Name of region to highlight"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load organization meta-info
lookup <- read_delim(opt$lookup, delim = "\t", col_types = readr::cols()) %>%
  select(cwts_org_no, country_iso_alpha, region) %>%
  filter(country_iso_alpha == opt$country) # select only the specified country

# Load the axis data and filter to only specified countries
sims <- read_csv(opt$input, col_types = readr::cols()) %>%
  inner_join(lookup, by = "cwts_org_no")

x_ceiling <- ceiling(max(abs(sims$sim)) * 50) / 50
label_size <- max(nchar(c(opt$endlow, opt$endhigh)))

# compute averages for each place
averages <- sims %>%
  group_by(region) %>%
  summarize(
    mu = mean(sim)
  ) %>%
  ungroup() %>%
  filter(region %in% c(opt$place1, opt$place2))

print(averages)
print(x_ceiling)
print(label_size)
print(head(sims))
print(opt$place1)
print(opt$place2)
plot <- sims %>%
  mutate(
    highlight = ifelse(region == opt$place1, opt$place1code,
                       ifelse(region == opt$place2, opt$place2code, "Other"))
  ) %>%
  ggplot(aes(x = sim, y = 0,
         color = highlight,
         alpha = ifelse(highlight == "Other",
                        NOT_HIGHLIGHTED_ALPHA,
                        1
                  ) # end ifelse
          ) # end aes
  ) + # end ggplot
  geom_segment(y = -1, yend = 1, aes(xend = sim)) + # Add lines for organizations
  geom_hline(yintercept = 0, size = 1) + # add center line, purely aesthetic
  geom_segment(y = -0.2, yend = 0.2, x = 0, xend = 0, size = 1, color = "black") +
  # Add the average markers
  geom_point(data = averages,
             aes(x = mu, y = 0),
             color = ifelse(averages$region == opt$place1, PLACE1_COLOR, PLACE2_COLOR),
             alpha = 1,
             size = 5,
             shape = 21,
             stroke = 2
  ) +
  xlim(-x_ceiling, x_ceiling) +
  scale_y_continuous(
    limits = c(-1.1, 1.1),
    name = stringr::str_pad(opt$endlow, label_size, side = "both"),
    sec.axis = dup_axis(name = stringr::str_pad(opt$endhigh, label_size, side = "both")),
  ) +
  scale_color_manual(values = c(PLACE1_COLOR, PLACE2_COLOR, "grey")) +
  guides(alpha = F,
         color = guide_legend(override.aes = list(size = 2))
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    axis.text.y = element_blank(),
    axis.title.x = element_blank(),
    axis.text.x = element_text(size = 11),
    axis.title.y.left = element_text(angle = 0, vjust = 0.5),
    axis.title.y.right = element_text(angle = 0, vjust = 0.5),
    panel.grid = element_blank()
  )

# Standardize the panel size
p <- egg::set_panel_size(plot,
                         width  = unit(FIG_WIDTH, "in"),
                         height = unit(FIG_HEIGHT, "in"))

# Save the plot
ggsave(opt$output, p, width = FIG_WIDTH + 2, height = FIG_HEIGHT + 1)

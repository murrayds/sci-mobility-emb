#
# PlotOrgDimReducedEmbedding.R
#
# author: Dakota Murray
#
# Visualizes a dim-reduced file (probably with umap) as either static or interactive.
# This script is tuned for plotting the organization
#

library(dplyr)
library(ggplot2)

POINT_SIZE = 0.8
POINT_ALPHA = 0.8

PLOT_WIDTH = 10
PLOT_HEIGHT = 8

# Parse command line argument
# First = Raw transition data
# 2 = The lookup file containing country information
# 3 = The path to the country lookup file
# last = Output file
args = commandArgs(trailingOnly=TRUE)

COMPONENTS_PATH = first(args)
ORG_LOOKUP_TABLE_PATH = args[2]
COUNTRY_LOOKUP_PATH = args[3]
OUTPUT_FILE_PATH = last(args)

# Read the components of the dim-reduced embedding
org_components <- readr::read_csv(COMPONENTS_PATH, col_types = readr::cols())

# Open the lookup paths
org_lookup <- readr::read_delim(ORG_LOOKUP_TABLE_PATH, delim = "\t", col_types = readr::cols())
country_lookup <- readr::read_delim(COUNTRY_LOOKUP_PATH, delim = "\t", col_types = readr::cols())

# Create a table linking organizational metadata with coordinates
org_components_detailed <- org_components %>%
  left_join(org_lookup, by = c("token" = "cwts_org_no")) %>%
  left_join(country_lookup, by = c("country_iso_alpha" = "Alpha_code_3"))

g <- org_components_detailed %>%
    filter(!is.na(Continent_name)) %>%
    ggplot(aes(x = axis1, y = axis2,
               color = Continent_name,
               shape = Continent_name,
               # These labels are used for ggplotly, if the plot is interactive
               label = full_name,
               label2 = city,
               label3 = Country_name,
               label4 = Continent_name,
               label5 = org_type)) +
    geom_point(size = POINT_SIZE, alpha = POINT_ALPHA) +
    theme_minimal() +
    guides(color = guide_legend(override.aes = list(size=5)),
           shape = guide_legend(override.aes = list(size=5))) +
    scale_color_brewer(palette = "Set2") +
    theme(legend.position = "bottom")

# If the file extension of the output file is a .html, that means that we are
# plotting a dynamic html. Otherwise we are plotting a static pdf.
PLOT_HTML = ifelse(tools::file_ext(OUTPUT_FILE_PATH) == "html", TRUE, FALSE)

# If set to static, then save now
if (PLOT_HTML) {
  # If set to interactive, then use ggplotly to form the plot and save as an html file
  ggp <- plotly::ggplotly(g, tooltip = c("full_name", "city", "Country_name", "Continent_name", "org_type"))
  htmlwidgets::saveWidget(ggp, OUTPUT_FILE_PATH)
} else {
  ggsave(OUTPUT_FILE_PATH, g, width = PLOT_WIDTH, height = PLOT_HEIGHT)
}

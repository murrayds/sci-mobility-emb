#
# PlotCityDimReducedEmbedding.R
#
# author: Dakota Murray
#
# Visualizes a dim-reduced file (probably with umap) as either static or interactive.
# This script is tuned for plotting the city-level embeddings
#

library(dplyr)
library(ggplot2)

TEXT_SIZE = 4.0

PLOT_WIDTH = 10
PLOT_HEIGHT = 8

# Parse command line argument
# First = Raw transition data
# 2 = The path to the country lookup file
# last = Output file
args = commandArgs(trailingOnly=TRUE)

COMPONENTS_PATH = first(args)
COUNTRY_LOOKUP_PATH = args[2]
OUTPUT_FILE_PATH = last(args)

# Read the components of the dim-reduced embedding
country_components <- readr::read_csv(COMPONENTS_PATH, col_types = readr::cols())

# Open the lookup file
country_lookup <- readr::read_delim(COUNTRY_LOOKUP_PATH, delim = "\t", col_types = readr::cols())

# Create a table linking organizational metadata with coordinates
country_components_detailed <- country_components %>%
  left_join(country_lookup, by = c("token" = "Alpha_code_3"))

g <- country_components_detailed %>%
    filter(!is.na(Continent_name)) %>%
    ggplot(aes(x = axis1, y = axis2,
               label = token,
               color = Continent_name,
               shape = Continent_name,
               # Just used for tooltips in plotly
               label2 = Country_name
              )
           ) +
    geom_text(size = TEXT_SIZE) +
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
  ggp <- plotly::ggplotly(g, tooltip = c("Country_name", "Continent_name"))
  htmlwidgets::saveWidget(ggp, OUTPUT_FILE_PATH)
} else {
  ggsave(OUTPUT_FILE_PATH, g, width = PLOT_WIDTH, height = PLOT_HEIGHT)
}

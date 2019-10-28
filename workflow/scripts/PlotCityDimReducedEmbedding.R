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
city_components <- readr::read_csv(COMPONENTS_PATH, col_types = readr::cols())

# Open the lookup paths
org_lookup <- readr::read_delim(ORG_LOOKUP_TABLE_PATH, delim = "\t", col_types = readr::cols())
country_lookup <- readr::read_delim(COUNTRY_LOOKUP_PATH, delim = "\t", col_types = readr::cols())

# We use the organization lookup data to create a city lookup file
city_lookup <- org_lookup %>%
  select(c(city_country, city, country_iso_alpha)) %>%
  group_by(city_country) %>%
  slice(1) %>%
  rowwise() %>%
  mutate(city_country = gsub("[ ]", "_", city_country))

# Create a table linking organizational metadata with coordinates
city_components_detailed <- city_components %>%
  left_join(city_lookup, by = c("token" = "city_country")) %>%
  left_join(country_lookup, by = c("country_iso_alpha" = "Alpha_code_3"))

g <- city_components_detailed %>%
    filter(!is.na(Continent_name)) %>%
    ggplot(aes(x = axis1, y = axis2,
               color = Continent_name,
               shape = Continent_name,
               # These labels are used for ggplotly, if the plot is interactive
               label = city,
               label2 = Country_name,
               label3 = Continent_name)
             ) +
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
  ggp <- plotly::ggplotly(g, tooltip = c("city", "Country_name", "Continent_name"))
  htmlwidgets::saveWidget(ggp, OUTPUT_FILE_PATH)
} else {
  ggsave(OUTPUT_FILE_PATH, g, width = PLOT_WIDTH, height = PLOT_HEIGHT)
}

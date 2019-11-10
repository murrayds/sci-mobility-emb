#
# FixOrgCoordinates.R
#
# author: Dakota Murray
#
# Fix the orgainzation coordiantes
#
library(dplyr)

# Parse command line argument
# First = Raw transition data
# 2 = Lookup table containing org -> city/country information
# 3 = The target scale, "org", "city", or "country". Other info is ignored
# last = Output file
args = commandArgs(trailingOnly=TRUE)


suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organization lookup information"),
  make_option(c("-c", "--coordinates"), action="store", default=NA, type='character',
              help="Path to file containing fixed coordinates"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Get org lookup information
lookup <- readr::read_delim(opt$lookup, delim = "\t", col_types = readr::cols())

# Contains fixed coordinates
coords.fixed <- readr::read_delim(opt$coordinates, delim = "\t", col_types = readr::cols())

lookup.fixed <- lookup %>%
  # This can be removed in the future, but I am keeping redundant columns
  # because I am nervous of deleting columns
  select(-new_lat, -new_long) %>%
  left_join(coords.fixed, by = "cwts_org_no") %>%
  # Select the fixed coordiantes, when they are missing
  mutate(
    latitude = ifelse(latitude == "NULL", new_lat, latitude),
    longitude = ifelse(longitude == "NULL", new_long, longitude),
    ) %>%
  select(-new_lat, -new_long) # remove redundant coordiantes

# Write the output
readr::write_delim(lookup.fixed, path = opt$output, delim = "\t")

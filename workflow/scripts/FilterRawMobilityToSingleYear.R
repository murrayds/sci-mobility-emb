#
# FilterRawMobilityToSingleYear.R
#
# author: Dakota Murray
#
# Filters the raw mobility data to a single year, so that future computations can
# be more easily paralellized
#

library(dplyr)

# Parse command line argument
# First = Raw transition data
# 2 = The year to process (all others excluded)
# last = Output file
args = commandArgs(trailingOnly=TRUE)

RAW_MOBILITY_PATH = first(args)
YEAR_TO_FILTER_TO = args[2]
OUTPUT_FILE_PATH = last(args)

# Read the file
mobility.raw = readr::read_delim(RAW_MOBILITY_PATH, delim = "\t", col_types = readr::cols())

# Filter to year
mobility.filtered = mobility.raw %>%
  filter(pub_year == YEAR_TO_FILTER_TO) %>%
  select(c(cluster_id, cwts_org_no)) %>% # Keep the files small, we don't need these here
  rename("org" = cwts_org_no) # Keep the name slightly more verbose

# Write output
readr::write_csv(mobility.filtered, path = OUTPUT_FILE_PATH)

#
# AddMultiscaleInfoToMobility.R
#
# author: Dakota Murray
#
# The original transition data is collected at the institutional level. However,
# we also want to examine embeddings at the level of the city and the country.
# To keep files small, we will replace the
#
library(dplyr)

# Parse command line argument
# First = Raw transition data
# 2 = Lookup table containing org -> city/country information
# 3 = The target scale, "org", "city", or "country". Other info is ignored
# last = Output file
args = commandArgs(trailingOnly=TRUE)

RAW_MOBILITY_PATH = first(args)
LOOKUP_PATH = args[2]
TARGET_SCALE = args[3]
OUTPUT_FILE_PATH = last(args)

# Read the mobility file
mobility.raw = readr::read_csv(RAW_MOBILITY_PATH, col_types = readr::cols())

# Read the Multiscale lookup table
lookup.table = readr::read_delim(LOOKUP_PATH, delim = "\t", col_types = readr::cols())

# Join the lookup table and keep only what we are interested in
mobility.at.scale = mobility.raw %>%
  left_join(lookup.table, by = "org") %>%
  select(cluster_id, TARGET_SCALE)

# Write the output
readr::write_csv(mobility.at.scale, path = OUTPUT_FILE_PATH)

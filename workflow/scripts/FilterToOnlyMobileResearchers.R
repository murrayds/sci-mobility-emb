#
# FilterToOnlyMobileResearchers.R
#
# author: Dakota Murray
#
# Filters the raw mobility data to only mobile researchers
#

library(dplyr)
library(readr)

# Parse command line argument
# First = Raw transition data
# 2 = The year to process (all others excluded)
# last = Output file
args = commandArgs(trailingOnly=TRUE)

RAW_MOBILITY_PATH = first(args)
RESEARCHER_META = args[2]
OUTPUT_FILE_PATH = last(args)

# Read the file
mobility.raw = read_delim(RAW_MOBILITY_PATH, delim = "\t", col_types = cols())

# Read the meta-info, which will make the filtering process quicker
researcher.meta <- read_delim(RESEARCHER_META,
                            delim = "\t",
                            col_types = cols_only(cluster_id = col_integer(),
                                                  org_mobile = col_logical())
                            ) %>% # end read_csv
                    filter(org_mobile == T) %>% # filter to only mobile researchers
                    select(cluster_id) # keep only the cluster id

# Perform the filtering
mobility.filtered <- mobility.raw %>%
  inner_join(researcher.meta, by = "cluster_id") %>%
  arrange(cluster_id, pub_year)

# Write output
readr::write_delim(mobility.filtered, path = OUTPUT_FILE_PATH, delim = "\t")

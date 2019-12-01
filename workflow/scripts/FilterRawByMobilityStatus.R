#
# FilterToOnlyMobileResearchers.R
#
# author: Dakota Murray
#
# Filters the raw mobility data to only mobile or nonmobile researchers
#

library(dplyr)
library(readr)
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing raw mobility transitions"),
  make_option(c("-r", "--researchers"), action="store", default=NA, type='character',
              help="Path to file containing researcher meta-information"),
  make_option(c("--mobile"), action="store_true", default=TRUE,
              help="If set, filter to mobile researchers"),
  make_option(c("--nonmobile"), action="store_false", default=FALSE,
              dest = "mobile", help="If set, filter to non-mobile researchers"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save aggregated distance file")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the file
mobility.raw = read_delim(opt$input, delim = "\t", col_types = cols())

# Read the meta-info, which will make the filtering process quicker
researcher.meta <- read_delim(opt$researchers,
                              delim = "\t",
                              col_types = cols_only(cluster_id = col_integer(),
                                                  org_mobile = col_logical())
                              ) %>% # end read_csv
                    filter(org_mobile == opt$mobile) %>% # filter to only mobile researchers
                    select(cluster_id) # keep only the cluster id

# Perform the filtering
mobility.filtered <- mobility.raw %>%
  inner_join(researcher.meta, by = "cluster_id") %>%
  arrange(cluster_id, pub_year)

# Write output
readr::write_delim(mobility.filtered, path = opt$output, delim = "\t")

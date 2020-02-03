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


# Perform the filtering
mobility.filtered <- mobility.raw %>%
  group_by(cluster_id, cwts_org_no) %>%
  filter(n() > 1) %>%
  arrange(cluster_id, pub_year)

# Write output
readr::write_delim(mobility.filtered, path = opt$output, delim = "\t")

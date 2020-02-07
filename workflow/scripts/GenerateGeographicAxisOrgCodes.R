#
# GenerateGeographicAxisOrgCodes.R
#
# author: Dakota Murray
#
# Create the file for the geogrpahic axis, i.e., California to Massechuessets
#
library(dplyr)
library(readr)

# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing organization info (lookup file)"),
  make_option(c("--scale"), action="store", default=NA, type='character',
              help="Name of the geographic scale vairable to use"),
  make_option(c("--place1"), action="store", default=NA, type='character',
              help="Name of the place at one end of the axis"),
  make_option(c("--place2"), action="store", default=NA, type='character',
              help="Name of place at the other end of the axis"),
  make_option(c("--norgs"), action="store", default=NA, type='integer',
              help="Number of orgs to sample from geographic areas"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

df <- readr::read_delim(opt$input, col_types = cols(), delim = "\t") %>%
  rename(type = opt$scale) %>%
  filter(type %in% c(opt$place1, opt$place2)) %>%
  sample_n(opt$norgs) %>%
  select(cwts_org_no, type)

# Write the output
readr::write_csv(df, path = opt$output)

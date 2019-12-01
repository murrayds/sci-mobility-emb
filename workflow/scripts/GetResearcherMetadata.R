#
# GetResearcherMetadata.R
#
# author: Dakota Murray
#
# Gets infomration about the individual, including whether they are mobile at
# the level of the institution, city, region, or country
#

library(dplyr)

# Parse command line argument
# First = Raw transition data
# 2 = The year to process (all others excluded)
# last = Output file
args = commandArgs(trailingOnly=TRUE)

# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing raw mobility information"),
  make_option(c("-l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organization lookup information"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the file
mobility.raw = readr::read_delim(opt$input,
                                 delim = "\t",
                                 col_types = readr::cols())

org.lookup <- readr::read_delim(opt$lookup,
                               delim = "\t",
                               col_types = readr::cols())

# Calcualte meta-information for each individual
researcher.meta <- mobility.raw %>%
  left_join(org.lookup, by = "cwts_org_no") %>%
  group_by(cluster_id) %>%
  summarize(
   num_org = length(unique(cwts_org_no)),
   num_city = length(unique(city)),
   num_region = length(unique(region)),
   num_country = length(unique(country_iso_alpha)),
   org_mobile = num_org > 1,
   city_mobile = num_city > 1,
   region_mobile = num_region > 1,
   country_mobile = num_country > 1,
   num_fields = length(unique(LR_main_field_no))
 )

# Write output
readr::write_delim(researcher.meta, path = opt$output, delim = "\t")

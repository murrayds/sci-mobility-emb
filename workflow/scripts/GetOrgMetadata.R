#
# GetResearcherMetadata.R
#
# author: Dakota Murray
#
# Gets infomration about the user, including whether they are mobile at
# the level of the institution, city, region, or country
#

library(dplyr)
library(readr)
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
  make_option(c("-r", "--researchers"), action="store", default=NA, type='character',
              help="Path to file containing researcher metadata"),
  make_option(c("-l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organization lookup information"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))


# Read the file
mobility.raw = read_delim(opt$input,
                          delim = "\t",
                          col_types = readr::cols())

org.lookup <- read_delim(opt$lookup,
                         delim = "\t",
                         col_types = readr::cols())

# Read the meta-info, which will make the filtering process quicker
researcher.meta <- read_delim(opt$researchers,
                              delim = "\t",
                              col_types = cols_only(cluster_id = col_integer(),
                                                    org_mobile = col_logical())
                              )

# Calculate the organization metadata
org.meta <- mobility.raw %>%
  # Researcher meta-info
  left_join(researcher.meta, by = "cluster_id") %>%
  select(cwts_org_no, cluster_id, org_mobile) %>%
  # Calculate the number of unique individuals
  group_by(cwts_org_no, org_mobile) %>%
  summarize(num_researchers = length(unique(cluster_id))) %>%
  tidyr::spread(org_mobile, num_researchers) %>%
  rename(nonmobile = `FALSE`, mobile = `TRUE`) %>%
  # Calculate total researchers and proportion of mobile/nonmobile
  mutate(total = nonmobile + mobile,
         prop.mobile = mobile / total) %>%
  arrange(desc(prop.mobile)) %>%
  left_join(org.lookup, by = "cwts_org_no") %>%
  select(cwts_org_no, mobile, nonmobile, total, prop.mobile, full_name, city, region, country_iso_alpha)

# Write output
write_delim(org.meta, path = opt$output, delim = "\t")

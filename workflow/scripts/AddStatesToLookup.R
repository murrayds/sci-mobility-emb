#
# AddStatesToLookup.R
#
# author: Dakota Murray
#
# Add state-level infomration to the organization lookup file
#
library(dplyr)

# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-l", "--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organization lookup information"),
  make_option(c("-s", "--states"), action="store", default=NA, type='character',
              help="Path to file containing state information for organizations"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Get org lookup information
lookup <- readr::read_delim(opt$lookup, delim = "\t", col_types = readr::cols())

# Contains fixed coordinates
states <- readr::read_csv(opt$states, col_types = readr::cols()) %>%
  # select the english name, if available
  mutate(region = ifelse(is.na(nameen), state, nameen)) %>%
  select(cwts_org_no, region)

lookup.with.states <- lookup %>%
  left_join(states, by = "cwts_org_no")


# Write the output
readr::write_delim(lookup.with.states, path = opt$output, delim = "\t")

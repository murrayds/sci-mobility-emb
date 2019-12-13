#
# ConvertFlowsToNetworkEdgelist.R
#
# author: Dakota Murray
#
# Convert the organization flows into an edgelist representation of a network
# that can loaded into common graph software such as Gephi
#

library(dplyr)
# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing organization flows"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Get org lookup information
flows <- readr::read_csv(opt$input, col_types = readr::cols()) %>%
  # Convert names to Source, Target, and weight, which is what igraph expects
  rename(Source = org1, Target = org2, weight = count) %>%
  filter(weight > 0) %>% # remove 0 weights, they simply take up memory
  filter(Source != Target) # Remove self flows, they are equally not informative here

# write the output
readr::write_csv(flows, path = opt$output)

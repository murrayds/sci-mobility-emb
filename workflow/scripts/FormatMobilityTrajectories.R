#
# FormatMobilityTrajectories.R
#
# author: Dakota Murray
#
# Apply formatting rules to the mobility trajectories.
#
# Raw - no action is applied (as of now), just move to next step
#
# Precedence - use pre-computed precedence rules to remove generla org identifiers
#              when a more specific one is already present
#

library(dplyr)
library(readr)
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing raw mobility transitions"),
  make_option(c("--traj"), action="store", default="raw", type="character",
              help="Option to set action for trajectory formatting. Currently
                    supports: 'raw', 'precedence'"),
  make_option(c("--precedence"), action = "store", default=NA, type="character",
              help="Path to the pre-computed precedence rules"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save aggregated distance file")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the file
# If raw, save the file
mobility <- read_delim(opt$input, delim = "\t", col_types = cols())

if (opt$traj == "precedence") {
  # Load the precedene rules
  precedence <- read_delim(opt$precedence, delim = "\t", col_types = cols())

  # Build a dataframe of cluster_id/org combinations that need to be removed
  mobility.toremove <- mobility %>%
    left_join(precedence, by = c("cwts_org_no" = "specific")) %>%
    group_by(cluster_id) %>%
    filter(any(!is.na(general))) %>% # keep only people where specific uni is present
    filter(cwts_org_no %in% general) %>% # keep only relevant rows
    select(cluster_id, cwts_org_no)

  mobility <- mobility %>%
    anti_join(mobility.toremove)
}


# Write output
readr::write_delim(mobility, path = opt$output, delim = "\t")

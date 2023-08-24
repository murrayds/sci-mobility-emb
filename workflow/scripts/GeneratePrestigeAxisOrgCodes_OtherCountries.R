#
# GeneratePrestigeAxisOrgCodes.R
#
# author: Dakota Murray
#
# Create the file for the pretige axis
#
library(dplyr)
library(readr)

# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing ranking information"),
  make_option(c("--variable"), action="store", default=NA, type='character',
              help="Name of the ranking variable to use from the file"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing org information, for filtering"),
  make_option(c("--country"), action="store", default=NA, type='character',
              help="3-digit ISO country code"),
  make_option(c("--norgs"), action="store", default=NA, type='integer',
              help="Number of orgs to sample from prestige poles"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

lookup <- read_delim(opt$lookup, col_types = cols(), delim = "\t")

df <- readr::read_csv(opt$input, col_types = cols()) %>%
  rename(score = opt$variable) %>%
  left_join(lookup, by = "cwts_org_no") %>%
  filter(country_iso_alpha == opt$country & org_type_code == "U")


elite <- df %>%
  top_n(opt$norgs, score)  %>%
  mutate(type = "Elite")

# Count th enumber of univeristies per region among elite univeristies
t <- table(elite$census_division)

# Sample non-elite univeristies
nonelite <- df %>%
  top_n(-opt$norgs, score) %>%
  mutate(type = "Non-elite")

prestige <- data.table::rbindlist(list(elite, nonelite)) %>%
  select(cwts_org_no, type)

# Write the output
readr::write_csv(prestige, path = opt$output)

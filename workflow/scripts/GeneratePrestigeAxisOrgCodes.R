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
  make_option(c("--regions"), action="store", default=NA, type='character',
              help="Path to file containing region information"),
  make_option(c("--norgs"), action="store", default=NA, type='integer',
              help="Number of orgs to sample from prestige poles"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

regions <- read_csv(opt$regions, col_types = cols())
lookup <- read_delim(opt$lookup, col_types = cols(), delim = "\t")

df <- readr::read_csv(opt$input, col_types = cols()) %>%
  rename(score = opt$variable) %>%
  left_join(lookup, by = "cwts_org_no") %>%
  filter(country_iso_alpha == "USA" & org_type_code == "U") %>%
  left_join(regions, by = "region")

print(opt$norgs)
elite <- df %>%
  top_n(opt$norgs, score)  %>%
  mutate(type = "Elite")

# Count th enumber of univeristies per region among elite univeristies
t <- table(elite$census_division)

# Sample non-elite univeristies from bottom-ranked universiteis of each region
nonelite <- data.table::rbindlist(lapply(1:length(t), function(index) {
  sub_df <- df %>%
      filter(census_division == names(t[index])) %>%
      top_n(-t[index], score) %>%
      sample_n(t[index]) # ensure that the right number is sampled, in case of ties
  return(sub_df)
})) %>%
  mutate(type = "Non-elite")

prestige <- data.table::rbindlist(list(elite, nonelite)) %>%
  select(cwts_org_no, type)

# Write the output
readr::write_csv(prestige, path = opt$output)

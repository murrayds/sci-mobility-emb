#
# CalculateTrajPrecedenceRules.R
#
# author: Dakota Murray
#
# Calculates the precedence rules for organizations that can be used to filter
# trajectory combinations that don't add additional information.
#
# The key idea is that some specific organizations are -always- classified as the
# more general organization. Here, we calculate the proprtion of times two organizations
# occur together, and if 100%, then create a rule detailing the specific -> general org
# relationship. Later, when a specific org is present in someone's trajectory, we
# will remove the more general org.
#

MINIMUM_ORG_PRECEDENCE_THRESHOLD = 20

library(dplyr)
library(readr)
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing mobility transitions"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save aggregated distance file")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read the file
mobility <- read_delim(opt$input, delim = "\t", col_types = cols())

traj <- mobility %>%
  group_by(cluster_id) %>%
  summarize(
    traj = paste(unique(cwts_org_no), collapse = " "),
    count = n()
  ) %>%
  filter(count > 1)

org_counts <- mobility %>%
  group_by(cwts_org_no) %>%
  summarize(count = length(unique(cluster_id))
)

# Calculate the co_occurence matrix
out <- quanteda::fcm(c(traj$traj), context = "document")
# Convert into long format
cooccur_df <- setNames(reshape2::melt(as.matrix(out)), c('org1', 'org2', 'freq'))

df <- cooccur_df %>%
  filter(freq > 0) %>% # remove empty rows, useless to us
  group_by(org1) %>%
  arrange(desc(freq)) %>%
  slice(1) %>% # get the highest counts only,
  ungroup() %>%
  left_join(org_counts, by = c("org1" = "cwts_org_no")) %>%
  rename(n_org1 = count) %>%
  left_join(org_counts, by = c("org2" = "cwts_org_no")) %>%
  rename(n_org2 = count) %>%
  mutate(prop_org1 = freq / n_org1,
         prop_org2 = freq / n_org2) %>%
  filter(n_org1 > MINIMUM_ORG_PRECEDENCE_THRESHOLD &
                  (prop_org1 == 1 | prop_org2 == 1)) %>%
  mutate(
    specific = ifelse(prop_org1 == 1, org1, org2),
    general = ifelse(specific == org1, org2, org1)
  ) %>%
  select(c(specific, general)) %>%
  filter(!duplicated(specific))

# Write output
readr::write_delim(df, path = opt$output, delim = "\t")

#
# BuildAggregateDistanceFile.R
#
# author: Dakota Murray
#
# Aggregates and joins all relevant distances into a single file. Includes
# "Gravity" (P1 * P2 / F12), real flows, and cosine similarity from the embedding.
#
library(dplyr)
library(readr)
suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"

# Command line arguments
option_list = list(
  make_option(c("-s", "--sizes"), action="store", default=NA, type='character',
              help="Path to file containing organization sizes"),
  make_option(c("-f", "--flows"), action="store", default=NA, type='character',
              help="Path to file containing organization flows"),
  make_option(c("-l", "--orgs"), action="store", default=NA, type='character',
              help="Path to file containing organization information"),
  make_option(c("-g", "--geo"), action="store", default=NA, type='character',
              help="Path to file containing organization geographic distances"),
  make_option(c("-e", "--emb"), action="store", default=NA, type='character',
              help="Path to file containing organization embedding distances"),
  make_option(c("-o", "--out"), action="store", default=NA, type='character',
              help="Path to save aggregated distance file")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Read all the files
# Org sizes
org_sizes <- read_delim(opt$sizes, delim = "\t", col_types = cols())

# Org flows
org_flows <- read_csv(opt$flows, col_types = cols())

# Org lookup table
lookup <- read_delim(opt$orgs, delim = "\t", col_types = cols()) %>%
  select(cwts_org_no, city, region, country_iso_name)

# Org geographic distances
geographic_distance <- read_csv(opt$geo, col_types = cols())

# Org embedding similarities
embedding_similarities <- read_csv(opt$emb, col_types = cols())

# Aggregate sizes, which are stored yearly, as the average number of
# unique people per year.
org_sizes <- org_sizes %>%
  group_by(cwts_org_no) %>%
  summarize(
    all_person_count = mean(person_count)
  ) %>%
  arrange(desc(all_person_count))


# Get average yearly flows between institutions
org_flows <- org_flows %>%
  # Remove cases in the "diagonal" of the distance matrix
  filter(org1 != org2) %>%
  mutate(
    # impute missing flows with 1
    imputed_count = ifelse(count == 0, 1, count)
  )

# Build the aggregate distance matrix
distance_all <- org_flows %>%
  # join size for each organization
  left_join(org_sizes, by = c("org1" = "cwts_org_no")) %>%
  left_join(org_sizes, by = c("org2" = "cwts_org_no")) %>%
  # set appropriate names for org sizes
  rename(org1_size = all_person_count.x, org2_size = all_person_count.y) %>%
  # Join the geographic distance
  inner_join(geographic_distance, by = c("org1", "org2")) %>%
  rename(geo_distance = distance) %>%
  # Join the embedding similarities
  inner_join(embedding_similarities, by = c("org1", "org2")) %>%
  rename(emb_similarity = similarity) %>%
  # Calculate the "gravity", the product of sizes as a ratio of real flows.
  mutate(
    gravity = imputed_count / (org1_size * org2_size),
    # Threshold distances to be, at minimum, 1km
    geo_distance = ifelse(geo_distance < 1, 1, geo_distance)
  ) %>%
  # Add the information on city, region, and country for each org
  left_join(lookup, by = c("org1" = "cwts_org_no")) %>%
  rename(org1_city = city, org1_region = region, org1_country = country_iso_name) %>%
  left_join(lookup, by = c("org2" = "cwts_org_no")) %>%
  rename(org2_city = city, org2_region = region, org2_country = country_iso_name) %>%
  # Get only unique rows, many of these merge steps tend to add duplicates
  unique()

# Write the output
write_csv(distance_all, path = opt$out)

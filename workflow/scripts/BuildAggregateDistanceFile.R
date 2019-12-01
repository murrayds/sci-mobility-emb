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

# Org embedding similarities
embedding_similarities <- read_csv(opt$emb, col_types = cols())

# Lets limit the sizes of dataframes as we load them. Keep only the organizations
# in the embedding frame
unique_orgs <- unique(c(embedding_similarities$org1, embedding_similarities$org2))

# Org flows
org_flows <- read_csv(opt$flows, col_types = cols()) %>%
  filter(org1 %in% unique_orgs & org2 %in% unique_orgs)

# Org lookup table
lookup <- read_delim(opt$orgs, delim = "\t", col_types = cols()) %>%
  select(cwts_org_no, city, region, country_iso_name) %>%
  filter(cwts_org_no %in% unique_orgs) %>%
  distinct(cwts_org_no, .keep_all = TRUE)

# Org geographic distances
geographic_distance <- read_csv(opt$geo, col_types = cols()) %>%
  filter(org1 != org2) %>% # don't need to measure distance with itself
  filter(org1 %in% unique_orgs & org2 %in% unique_orgs)

# Aggregate sizes, which are stored yearly, as the average number of
# unique people per year.
org_sizes <- org_sizes %>%
  group_by(cwts_org_no) %>%
  summarize(
    all_person_count = mean(person_count)
  ) %>%
  arrange(desc(all_person_count)) %>%
  select(cwts_org_no, all_person_count)


# Get average yearly flows between institutions
org_flows <- org_flows %>%
  # Remove cases in the "diagonal" of the distance matrix
  filter(org1 != org2) %>%
  mutate(
    # impute missing flows with 1
    imputed_count = ifelse(count == 0, 1, count)
  ) %>%
  select(org1, org2, count, imputed_count)

# Build the aggregate distance matrix
distance_all <- org_flows %>%
  # join size for each organization
  left_join(org_sizes, by = c("org1" = "cwts_org_no")) %>%
  left_join(org_sizes, by = c("org2" = "cwts_org_no")) %>%
  # set appropriate names for org sizes
  rename(org1_size = all_person_count.x, org2_size = all_person_count.y)

# There are memory issues, remove unecessary dataframes
remove("org_sizes", "org_flows")


# Merge geographic distances
geo1 <- distance_all %>%
  inner_join(geographic_distance, by = c("org1" = "org1", "org2" = "org2"))

geo2 <- distance_all %>%
  inner_join(geographic_distance, by = c("org1" = "org2", "org2" = "org1"))

distance_all <- data.table::rbindlist(list(geo1, geo2)) %>%
  rename(geo_distance = distance) %>%
  distinct(org1, org2, .keep_all = TRUE) %>%
  mutate(
    geo_distance = ifelse(geo_distance < 1, 1, geo_distance)
  )

# Remove unecessary dataframes
remove("geo1", "geo2", "geographic_distance")


# Merge embedding distances
emb1 <- distance_all %>%
  inner_join(embedding_similarities, by = c("org1" = "org1", "org2" = "org2"))

emb2 <- distance_all %>%
  inner_join(embedding_similarities, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(emb1, emb2)) %>%
  rename(emb_similarity = similarity) %>%
  mutate(
    gravity = count / (org1_size * org2_size),
    gravity_imp = imputed_count / (org1_size * org2_size),
    # Threshold distances to be, at minimum, 1km
  ) %>%
  distinct(org1, org2, .keep_all = TRUE)

# remove the extra dataframes
remove("emb1", "emb2", "embedding_similarities")


# Merge the lookups
distance_all <- distance_all %>%
  # Add the information on city, region, and country for each org
  left_join(lookup, by = c("org1" = "cwts_org_no")) %>%
  rename(org1_city = city, org1_region = region, org1_country = country_iso_name) %>%
  left_join(lookup, by = c("org2" = "cwts_org_no")) %>%
  rename(org2_city = city, org2_region = region, org2_country = country_iso_name) %>%
  # Get only unique rows, many of these merge steps tend to add duplicates
  distinct(org1, org2, .keep_all = TRUE) %>%
  # Select only relevant variables
  select(c("org1", "org2", "count", "imputed_count", "org1_size", "org2_size",
           "geo_distance", "emb_similarity", "gravity", "gravity_imp",
           "org1_city", "org1_region", "org1_country", "org2_city",
           "org2_region", "org2_country"))


# Write the output
write_csv(distance_all, path = opt$out)

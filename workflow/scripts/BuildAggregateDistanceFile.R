#
# BuildAggregateDistanceFile.R
#
# author: Dakota Murray
#
# Aggregates and joins all relevant distances into a single file. Includes
# "Gravity" (F12 / P1 * P2), real flows, and cosine similarity from the embedding.
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
  make_option(c("--pprcos"), action="store", default=NA, type='character',
              help="Path to file containing organization PPR distances"),
  make_option(c("--pprjsd"), action="store", default=NA, type='character',
              help="Path to file containing organization PPR distances"),
  make_option(c("--lapcos"), action="store", default=NA, type='character',
              help="Path to file containing organization laplacian eigenmap distances"),
  make_option(c("--svdcos"), action="store", default=NA, type='character',
              help="Path to file containing organization singular value decomposition distances"),
  make_option(c("--dot"), action="store", default=NA, type='character',
              help="Path to file containing organization dot product similarities"),
  make_option(c("-o", "--out"), action="store", default=NA, type='character',
              help="Path to save aggregated distance file")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))



# Org embedding similarities
embedding_similarities <- read_csv(opt$emb, col_types = cols())

# Limit the sizes of dataframes as we load them. Keep only the organizations
# in the embedding frame, since many here will be removed during the
# embedding process
unique_orgs <- unique(c(embedding_similarities$org1, embedding_similarities$org2))


#
# ORG SIZES AND FLOWS
#

# Load org sizes
org_sizes <- read_delim(opt$sizes, delim = "\t", col_types = cols())

# Org flows
org_flows <- read_csv(opt$flows, col_types = cols()) %>%
  filter(org1 %in% unique_orgs & org2 %in% unique_orgs)

# Get average yearly flows between institutions
org_flows <- org_flows %>%
  # Remove cases in the "diagonal" of the distance matrix
  filter(org1 != org2) %>%
  select(org1, org2, count)

# Build the aggregate distance matrix
distance_all <- org_flows %>%
  # join size for each organization
  left_join(org_sizes, by = c("org1" = "cwts_org_no")) %>%
  left_join(org_sizes, by = c("org2" = "cwts_org_no")) %>%
  # set appropriate names for org sizes
  rename(org1_size = size.x, org2_size = size.y)

# There are memory issues, remove unecessary dataframes
remove("org_sizes", "org_flows")


#
# GEOGRAPHIC DISTANCES
#

# Load geographic distances
geographic_distance <- read_csv(opt$geo, col_types = cols()) %>%
  filter(org1 != org2) %>% # don't need to measure distance with itself
  filter(org1 %in% unique_orgs & org2 %in% unique_orgs)

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


#
# EMBEDDING DISTANCES
#

# Merge embedding distances, starting with cosine similarities
emb1 <- distance_all %>%
  inner_join(embedding_similarities, by = c("org1" = "org1", "org2" = "org2"))

emb2 <- distance_all %>%
  inner_join(embedding_similarities, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(emb1, emb2)) %>%
  rename(emb_similarity = similarity) %>%
  mutate(
    emb_distance = 1 - emb_similarity,
    gravity = count / (org1_size * org2_size),
    # Threshold distances to be, at minimum, 1km
  ) %>%
  distinct(org1, org2, .keep_all = TRUE)

# remove the extra dataframes
remove("emb1", "emb2", "embedding_similarities")

# Now merge dot product similarities
dot <- read_csv(opt$dot, col_types = cols()) %>%
  select(org1, org2, similarity) %>%
  rename(dot_distance = similarity)

dot1 <- distance_all %>%
  inner_join(dot, by = c("org1" = "org1", "org2" = "org2"))

dot2 <- distance_all %>%
  inner_join(dot, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(dot1, dot2)) %>%
  distinct(org1, org2, .keep_all = TRUE)

remove("dot", "dot1", "dot2")

# PPR Cosine distnaces
ppr <- read_csv(opt$pprcos, col_types = cols()) %>%
  select(org1, org2, distance) %>%
  rename(pprcos_distance = distance) %>%
  mutate(pprcos_distance = 1 - pprcos_distance)

ppr1 <- distance_all %>%
  inner_join(ppr, by = c("org1" = "org1", "org2" = "org2"))

ppr2 <- distance_all %>%
  inner_join(ppr, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(ppr1, ppr2)) %>%
  distinct(org1, org2, .keep_all = TRUE)

remove("ppr", "ppr1", "ppr2")


# PPR JSD
ppr <- read_csv(opt$pprjsd, col_types = cols()) %>%
  select(org1, org2, distance) %>%
  rename(pprjsd_distance = distance)

ppr1 <- distance_all %>%
  inner_join(ppr, by = c("org1" = "org1", "org2" = "org2"))

ppr2 <- distance_all %>%
  inner_join(ppr, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(ppr1, ppr2)) %>%
  distinct(org1, org2, .keep_all = TRUE)

remove("ppr", "ppr1", "ppr2")


# LAP COS
lapcos <- read_csv(opt$lapcos, col_types = cols()) %>%
  select(org1, org2, distance) %>%
  rename(lapcos_distance = distance)

lapcos1 <- distance_all %>%
  inner_join(lapcos, by = c("org1" = "org1", "org2" = "org2"))

lapcos2 <- distance_all %>%
  inner_join(lapcos, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(lapcos1, lapcos2)) %>%
  distinct(org1, org2, .keep_all = TRUE)

remove("lapcos", "lapcos1", "lapcos2")


# SVD COS
svdcos <- read_csv(opt$svdcos, col_types = cols()) %>%
  select(org1, org2, distance) %>%
  rename(svdcos_distance = distance)

svdcos1 <- distance_all %>%
  inner_join(svdcos, by = c("org1" = "org1", "org2" = "org2"))

svdcos2 <- distance_all %>%
  inner_join(svdcos, by = c("org2" = "org1", "org1" = "org2"))

distance_all <- data.table::rbindlist(list(svdcos1, svdcos2)) %>%
  distinct(org1, org2, .keep_all = TRUE)

remove("svdcos", "svdcos1", "svdcos2")

#
# ORG LOOKUP TABLES
#

# Load the org lookup table
lookup <- read_delim(opt$orgs, delim = "\t", col_types = cols()) %>%
  select(cwts_org_no, city, region, country_iso_name) %>%
  filter(cwts_org_no %in% unique_orgs) %>%
  distinct(cwts_org_no, .keep_all = TRUE)

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
  select(org1, org2, count,
         org1_size, org2_size,
         geo_distance, emb_distance, dot_distance,
         pprcos_distance, pprjsd_distance,
         lapcos_distance, svdcos_distance,
         gravity,
         org1_city, org1_region, org1_country,
         org2_city, org2_region, org2_country
  )


# Write the output
write_csv(distance_all, path = opt$out)

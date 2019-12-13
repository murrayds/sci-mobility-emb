#
# GetAggregateR2.R
#
# author: Dakota Murray
#
# Iterates through a list of aggregate files, getting the R2 of each, and
# stores them all into a single file
#

NUM_REPLICATIONS = 500
NUM_WORKERS = 4


library(dplyr)
library(readr)
library(boot)
# Command line arguments
# Optparse doesn't have a way of taking arbitrary files as input, so use default
# argument parsing
args = commandArgs(trailingOnly=TRUE)

DISTANCE_FILES = args[1:length(args) - 1]
OUTPUT_FILE_PATH = last(args)

# This helper function simply calculates the boostrapped R2 and confidence
# interval for each correlation case
get_correlations <- function(distance_data) {

  global.boot <- boot(distance_data %>% select(gravity, distance),
                      function(data, indices) {
                        summary(lm(gravity ~ distance,
                                 distance_data[indices, ])
                        )$r.squared
                      }, R = NUM_REPLICATIONS,
                      parallel = "multicore", ncpus = NUM_WORKERS
                    )

  samecountry.boot <- boot(distance_data %>%
                            filter(org1_country == org2_country) %>%
                            select(gravity, distance),
                           function(data, indices) {
                             summary(lm(gravity ~ distance,
                                        distance_data[indices, ])
                             )$r.squared
                           }, R = NUM_REPLICATIONS,
                           parallel = "multicore", ncpus = NUM_WORKERS
                      )

  diffcountry.boot <- boot(distance_data %>%
                            filter(org1_country != org2_country) %>%
                            select(gravity, distance),
                           function(data, indices) {
                             summary(lm(gravity ~ distance,
                                        distance_data[indices, ])
                             )$r.squared
                           }, R = NUM_REPLICATIONS,
                           parallel = "multicore", ncpus = NUM_WORKERS
                      )

  # Iterate through each of these bootstrap results and calculate the basic CI
  df <- data.table::rbindlist(lapply(list(global.boot, samecountry.boot, diffcountry.boot), function(b) {

    ci = boot.ci(b, conf = 0.99, type = "basic")
    r2 <- ci[["t0"]]
    ci.lower = ci[["basic"]][4]
    ci.upper = ci[["basic"]][5]
    return(data.frame(r2 = r2, ci.lower = ci.lower, ci.upper = ci.upper))
  }))

  # Set the names for the cases
  df$case = c("global", "same-country", "diff-country")

  return(df)
}

# Iterate through each given input file
agg <- data.table::rbindlist(lapply(DISTANCE_FILES, function(path) {

  # Load the file, perform the necessary transformations and remove
  # unecessary data
  distance_data <- read_csv(path, col_types = cols()) %>%
    filter(count > 0) %>%
    mutate(gravity = log10(gravity),
           geo_distance = log10(geo_distance)
    ) %>%
    select(-c(org1_city, org2_city, org1_region, org2_region, org1_size, org2_size, count))

  # Rename geo_distnace to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = geo_distance) %>%
    select(-geo_distance)

  df1 <- get_correlations(distance_data)
  df1$metric = "geo"

  # Rename emb_similarity to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = emb_similarity) %>%
    select(-emb_similarity)

  df2 <- get_correlations(distance_data)
  df2$metric = "emb"

  # merge the two mini data frames
  df <- data.table::rbindlist(list(df1, df2))

  # Specity the parameters of the file, including the embedding dimensions
  # and window size
  filename.split <- unlist(strsplit(path, "_"))
  df$dim <- as.numeric(gsub("[^0-9.-]", "", filename.split[4]))
  df$ws <- as.numeric(gsub("[^0-9.-]", "", filename.split[5]))

  return(df)
}))


# Write the output
write_csv(agg, path = OUTPUT_FILE_PATH)

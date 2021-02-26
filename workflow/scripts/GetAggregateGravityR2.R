#
# GetAggregateR2.R
#
# author: Dakota Murray
#
# Iterates through a list of aggregate files, getting the R2 of each, and
# stores them all into a single file
#

NUM_REPLICATIONS = 5
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

  same_country <- distance_data %>%
    filter(org1_country == org2_country) %>%
    select(gravity, distance)

  samecountry.boot <- boot(same_country,
                           function(data, indices) {
                             summary(lm(gravity ~ distance,
                                        same_country[indices, ])
                             )$r.squared
                           }, R = NUM_REPLICATIONS,
                           parallel = "multicore", ncpus = NUM_WORKERS
                      )

  rm(same_country)
  diff_country <- distance_data %>%
    filter(org1_country != org2_country) %>%
    select(gravity, distance)
  diffcountry.boot <- boot(diff_country,
                           function(data, indices) {
                             summary(lm(gravity ~ distance,
                                        diff_country[indices, ])
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

  print(paste0("Running bootstrap for file: ", path))

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

  # Rename emb_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = emb_distance) %>%
    select(-emb_distance)

  df2 <- get_correlations(distance_data)
  df2$metric = "emb"

  # Rename lapcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = lapcos_distance) %>%
    select(-lapcos_distance)

  df3 <- get_correlations(distance_data)
  df3$metric = "lapcos"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = svdcos_distance) %>%
    select(-svdcos_distance)

  df4 <- get_correlations(distance_data)
  df4$metric = "svdcos"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = pprcos_distance) %>%
    select(-pprcos_distance)

  df5 <- get_correlations(distance_data)
  df5$metric = "pprcos"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = pprjsd_distance) %>%
    select(-pprjsd_distance)

  df6 <- get_correlations(distance_data)
  df6$metric = "pprjsd"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = dot_distance) %>%
    select(-dot_distance)

  df7 <- get_correlations(distance_data)
  df7$metric = "dot"


  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = levycos_distance) %>%
    select(-levycos_distance)

  df8 <- get_correlations(distance_data)
  df8$metric = "levycos"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = levyeuc_distance) %>%
    select(-levyeuc_distance)

  df9 <- get_correlations(distance_data)
  df9$metric = "levyeuc"

  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = levydot_distance) %>%
    select(-levydot_distance)

  df10 <- get_correlations(distance_data)
  df10$metric = "levydot"


  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = log(gravsvd_distance)) %>%
    select(-gravsvd_distance)

  df11 <- get_correlations(distance_data)
  df11$metric = "gravsvd"


  # Rename svdcos_distance to "distance", remove the old column
  distance_data <- distance_data %>%
    mutate(distance = log(gravmds_distance)) %>%
    select(-gravmds_distance)

  df12 <- get_correlations(distance_data)
  df12$metric = "gravmds"


  # merge the two mini data frames
  df <- data.table::rbindlist(list(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12))

  # Specity the parameters of the file, including the embedding dimensions
  # and window size
  filename.split <- unlist(strsplit(path, "_"))
  df$traj <- filename.split[4]
  df$dim <- as.numeric(gsub("[^0-9.-]", "", filename.split[5]))
  df$ws <- as.numeric(gsub("[^0-9.-]", "", filename.split[6]))
  df$gamma <- as.numeric(gsub("[^0-9.-]", "", filename.split[7]))
  df$sizetype <- gsub("(size)|(.csv)", "", filename.split[8])

  return(df)
}))


# Write the output
write_csv(agg, path = OUTPUT_FILE_PATH)

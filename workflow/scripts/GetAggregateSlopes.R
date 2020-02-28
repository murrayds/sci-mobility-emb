#
# GetAggregateSlopes.R
#
# author: Dakota Murray
#
# Iterates through a list of aggregate files, getting the slope of the line of
# best fit for variables in the file.
#

library(dplyr)
library(readr)
library(boot)
# Command line arguments
# Optparse doesn't have a way of taking arbitrary files as input, so use default
# argument parsing
args = commandArgs(trailingOnly=TRUE)

DISTANCE_FILES = args[1:length(args) - 1]
OUTPUT_FILE_PATH = last(args)

# Iterate through each given input file
agg <- data.table::rbindlist(lapply(DISTANCE_FILES, function(path) {

  print(paste0("Loading file: ", path))

  # Load the file, perform the necessary transformations and remove
  # unecessary data
  dist <- read_csv(path, col_types = cols()) %>%
    filter(count > 0) %>%
    mutate(gravity = log10(gravity),
           geo_distance = log10(geo_distance),
           same_country = org1_country == org2_country,
           diff_country = org1_country != org2_country
    ) %>%
    select(gravity, geo_distance, emb_distance, pprcos_distance, pprjsd_distance, same_country, diff_country)


    # Global fits
    global_geo = coef(lm(gravity ~ geo_distance, data = dist))[2]
    global_pprcos = coef(lm(gravity ~ pprcos_distance, data = dist))[2]
    global_pprjsd = coef(lm(gravity ~ pprjsd_distance, data = dist))[2]
    global_emb = coef(lm(gravity ~ emb_distance, data = dist))[2]

    # Same-country fits
    same_dist <- dist %>% filter(same_country)
    same_geo = coef(lm(gravity ~ geo_distance, data = same_dist))[2]
    same_pprcos = coef(lm(gravity ~ pprcos_distance, data = same_dist))[2]
    same_pprjsd = coef(lm(gravity ~ pprjsd_distance, data = same_dist))[2]
    same_emb = coef(lm(gravity ~ emb_distance, data = same_dist))[2]

    # Different-country fits
    diff_dist <- dist %>% filter(diff_country)
    diff_geo = coef(lm(gravity ~ geo_distance, data = diff_dist))[2]
    diff_pprcos = coef(lm(gravity ~ pprcos_distance, data = diff_dist))[2]
    diff_pprjsd = coef(lm(gravity ~ pprjsd_distance, data = diff_dist))[2]
    diff_emb = coef(lm(gravity ~ emb_distance, data = diff_dist))[2]


    df <- data.frame(
      slope = c(global_geo, global_pprcos, global_pprjsd, global_emb,
                same_geo, same_pprcos, same_pprjsd, same_emb,
                diff_geo, diff_pprcos, diff_pprjsd, diff_emb),
      distance = rep(c("geo", "pprcos", "pprjsd", "emb"), 3),
      geo = c(rep("global", 4), rep("same", 4), rep("diff", 4))
    )

    # Specity the parameters of the file, including the embedding dimensions
    # and window size
    filename.split <- unlist(strsplit(path, "_"))
    df$traj <- filename.split[4]
    df$dim <- as.numeric(gsub("[^0-9.-]", "", filename.split[5]))
    df$ws <- as.numeric(gsub("[^0-9.-]", "", filename.split[6]))

    return(df)
}))


# Write the output
write_csv(agg, path = OUTPUT_FILE_PATH)

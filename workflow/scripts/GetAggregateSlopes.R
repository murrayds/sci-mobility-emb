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
    select(gravity, geo_distance, emb_distance,
           pprcos_distance, pprjsd_distance,
           lapcos_distance, svdcos_distance,
           same_country, diff_country)


    # Global fits
    global_geo = anova(lm(gravity ~ geo_distance, data = dist))[5]$`Pr(>F)`[1]
    global_pprcos = anova(lm(gravity ~ pprcos_distance, data = dist))[5]$`Pr(>F)`[1]
    global_pprjsd = anova(lm(gravity ~ pprjsd_distance, data = dist))[5]$`Pr(>F)`[1]
    global_emb = anova(lm(gravity ~ emb_distance, data = dist))[5]$`Pr(>F)`[1]
    global_lapcos = anova(lm(gravity ~ lapcos_distance, data = dist))[5]$`Pr(>F)`[1]
    global_svdcos = anova(lm(gravity ~ svdcos_distance, data = dist))[5]$`Pr(>F)`[1]

    # Same-country fits
    same_dist <- dist %>% filter(same_country)
    same_geo = anova(lm(gravity ~ geo_distance, data = same_dist))[5]$`Pr(>F)`[1]
    same_pprcos = anova(lm(gravity ~ pprcos_distance, data = same_dist))[5]$`Pr(>F)`[1]
    same_pprjsd = anova(lm(gravity ~ pprjsd_distance, data = same_dist))[5]$`Pr(>F)`[1]
    same_emb = anova(lm(gravity ~ emb_distance, data = same_dist))[5]$`Pr(>F)`[1]
    same_lapcos = anova(lm(gravity ~ lapcos_distance, data = same_dist))[5]$`Pr(>F)`[1]
    same_svdcos = anova(lm(gravity ~ svdcos_distance, data = same_dist))[5]$`Pr(>F)`[1]

    # Different-country fits
    diff_dist <- dist %>% filter(diff_country)
    diff_geo = anova(lm(gravity ~ geo_distance, data = diff_dist))[5]$`Pr(>F)`[1]
    diff_pprcos = anova(lm(gravity ~ pprcos_distance, data = diff_dist))[5]$`Pr(>F)`[1]
    diff_pprjsd = anova(lm(gravity ~ pprjsd_distance, data = diff_dist))[5]$`Pr(>F)`[1]
    diff_emb = anova(lm(gravity ~ emb_distance, data = diff_dist))[5]$`Pr(>F)`[1]
    diff_lapcos = anova(lm(gravity ~ lapcos_distance, data = diff_dist))[5]$`Pr(>F)`[1]
    diff_svdcos = anova(lm(gravity ~ svdcos_distance, data = diff_dist))[5]$`Pr(>F)`[1]

    df <- data.frame(
      slope = c(global_geo, global_pprcos, global_pprjsd, global_emb, global_lapcos, global_svdcos,
                same_geo, same_pprcos, same_pprjsd, same_emb, same_lapcos, global_svdcos,
                diff_geo, diff_pprcos, diff_pprjsd, diff_emb, diff_lapcos, diff_svdcos),
      distance = rep(c("geo", "pprcos", "pprjsd", "emb", "lapcos", "svdcos"), 3),
      geo = c(rep("global", 6), rep("same", 6), rep("diff", 6))
    )

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

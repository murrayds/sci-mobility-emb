#
# CalculatePredictedVsActual.R
#
# author: Dakota Murray
#
# Represents the organization flows as a single network and calculates shortest
# paths between all pairs of points
#

library(dplyr)
# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing aggregate distance information"),
  make_option(c("--geo"), action="store", default="none",
              help="Geographic constraint, none, or same or different country"),
  make_option(c("--distance"), action="store", default="none",
              help="One of 'geo' or 'emb', specifying which distance metric of the dataframe to use"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the data, select relevant columns
agg <- readr::read_csv(opt$input, col_types = readr::cols()) %>%
  filter(count > 0) %>%
  select(org1_size, org2_size,
         org1_country, org2_country,
         count, gravity,
         geo_distance, ppr_distance, emb_similarity) %>%
  rename(actual = count)

# If the geographic constraint (--geo) is set, then filter the
# distance dataframe accordingly.
if (opt$geo == "same-country") {
  agg <- agg %>% filter(org1_country == org2_country)
} else if (opt$geo == "different-country") {
  agg <- agg %>% filter(org1_country != org2_country)
}

#
# Calculate the expected value. We use two different equations depending on
# whether we are calculating it on geographic distance, or embedding similarity
#
if (opt$distance == "geo") {
  # Perform the regression
  fit <- summary(lm(log(gravity) ~ log(geo_distance), data = agg))
  geo_intercept <- fit$coefficients["(Intercept)", "Estimate"]
  geo_coef <- fit$coefficients["log(geo_distance)", "Estimate"]

  agg <- agg %>%
    mutate(
      # Calculate the expected value using the geographic distance formula
      expected = (org1_size * org2_size) * (geo_distance ^ (geo_coef)) * exp(geo_intercept)
    )

} else if (opt$distance == "emb") {
  fit <- summary(lm(log(gravity) ~ emb_similarity, data = agg))

  # Save the coefficients for use later
  intercept <- fit$coefficients["(Intercept)", "Estimate"]
  emb_coef <- fit$coefficients["emb_similarity", "Estimate"]

  agg <- agg %>%
    mutate(
      # Calculate the expected value using the embedding similarity formula
      expected = org1_size * org2_size * exp((emb_coef * emb_similarity) + intercept)
    )
} else if (opt$distance == "ppr") {
  fit <- summary(lm(log(gravity) ~ ppr_distance, data = agg))

  # Save the coefficients for use later
  intercept <- fit$coefficients["(Intercept)", "Estimate"]
  ppr_coef <- fit$coefficients["ppr_distance", "Estimate"]

  agg <- agg %>%
    mutate(
      # Calculate the expected value using the embedding similarity formula
      expected = org1_size * org2_size * exp((ppr_coef * ppr_distance) + intercept)
    )
}

agg <- agg %>%
  select(-c(org1_size, org2_size, gravity, geo_distance, emb_similarity))

# Write the output
readr::write_csv(agg, path = opt$output)

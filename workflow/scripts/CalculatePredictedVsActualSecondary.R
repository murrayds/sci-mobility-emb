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
  make_option(c("--distance"), action="store", default="none",
              help="One of 'geo' or 'emb', specifying which distance metric of the dataframe to use"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save distances")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the data, select relevant columns
agg <- readr::read_csv(opt$input, col_types = readr::cols()) %>%
  select(org1_size, org2_size,
         count, gravity,
         geo_distance, emb_distance) %>%
  rename(actual = count)


#
# Calculate the expected value. We use two different equations depending on
# whether we are calculating it on geographic distance, or embedding similarity
#
if (opt$distance == "geo") {
  # Perform the regression
  agg <- agg %>%
    mutate(
      distance = geo_distance,
      distance.log = log(geo_distance)
    )
} else if (opt$distance == "emb") {
  agg <- agg %>%
    mutate(
      distance = emb_distance,
      distance.log = log(emb_distance)
    )
}

fit.power <- summary(lm(log(gravity) ~ log(distance), data = agg))
intercept.power <- fit.power$coefficients["(Intercept)", "Estimate"]
coef.power <- fit.power$coefficients["log(distance)", "Estimate"]

fit.exp <- summary(lm(log(gravity) ~ distance, data = agg))
# Save the coefficients for use later
intercept.exp <- fit.exp$coefficients["(Intercept)", "Estimate"]
coef.exp <- fit.exp$coefficients["distance", "Estimate"]

agg <- agg %>%
  mutate(
    # Calculate the expected value using the geographic distance formula
    expected.power = (org1_size * org2_size) * (distance ^ (coef.power)) * exp(intercept.power),
    # Calculate the expected value using the embedding similarity formula
    expected.exp = org1_size * org2_size * exp((coef.exp * distance) + intercept.exp)
  )

agg <- agg %>%
  select(-c(org1_size, org2_size,
            gravity, geo_distance, emb_distance))


# Write the output
readr::write_csv(agg, path = opt$output)

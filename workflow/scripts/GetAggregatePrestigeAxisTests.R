#
# GetAggregatePrestigeAxisTests.R
#
# author: Dakota Murray
#
# Iterates through a list of prestige similarity files, comparing similarity scores
# along this axis with those from a ranking file, testing their equivelance
#

library(dplyr)
library(readr)

# Command line arguments
# Optparse doesn't have a way of taking arbitrary files as input, so use default
# argument parsing
args = commandArgs(trailingOnly=TRUE)

# In order to pass so many files, we will have to be a
# little primative with how we extract argumnets
LOOKUP_FILE = args[1] # The file containing lookup information
LOOKUP_COUNTRY = args[2] # The country to filter to
TIMES_RANKING_FILE = args[3] # The file containing the Times ranking
LEIDEN_RANKING_FILE = args[4] # The file containing the Leiden ranking
SEMAXIS_FILES = args[5:(length(args) - 1)]
OUTPUT_FILE_PATH = last(args)

lookup <- read_delim(LOOKUP_FILE, delim = "\t", col_types = cols()) %>%
 filter(country_iso_alpha == LOOKUP_COUNTRY) %>%
 select(cwts_org_no)

times <- read_csv(TIMES_RANKING_FILE, col_types = cols()) %>%
  rename(score = total_score) %>%
  select(cwts_org_no, score)

# Extract the ranking type from the path,
# only works now for the two ranking systems
leiden <- read_csv(LEIDEN_RANKING_FILE, col_types = cols()) %>%
 rename(score = impact_frac_mncs) %>%
 select(cwts_org_no, score)


# Iterate through each given input file
agg <- data.table::rbindlist(lapply(SEMAXIS_FILES, function(path) {
  filename.split <- unlist(strsplit(path, "_"))
  # Extract the ranking file from the path
  type <- ifelse(grepl("leiden", path, fixed = T), "leiden", "times")

  # Load and format the SemAxis data
  data <- read_csv(path, col_types = cols()) %>%
    inner_join(lookup, by = "cwts_org_no")

  # Add the appropriate rankings
  if (type == "leiden") {
    data <- data %>%
      left_join(leiden, by = "cwts_org_no", col_types = cols())
  } else {
    data <- data %>%
      left_join(times, by = "cwts_org_no", col_types = cols())
  }

  # determine which organizations were included, and which were excluded.
  n = as.numeric(gsub("[^0-9.-]", "", filename.split[4]))
  data <- data %>%
    arrange(desc(score)) %>%
    mutate(rank = row_number()) %>%
    mutate(included = ifelse(rank <= n | rank >= max(rank) - n,
                             TRUE, FALSE))

  # Calculate the spearman correlation between our simialrity
  # axis, and the scores from the ranking
  spear <- cor.test(~ sim + score,
                    data = data,
                    method = "spearman",
                    continuity = FALSE,
                    conf.level = 0.99)

  # Also calculate the spearman correlation using only the excluded values
  spear.excluded <- cor.test( ~ sim + score,
                             data=subset(data, included == F),
                             method = "spearman",
                             continuity = FALSE,
                             conf.level = 0.99)

  # Build dataframe, extracting relevant fields from the filename
  df <- data.frame(
    dim = as.numeric(gsub("[^0-9.-]", "", filename.split[2])),
    ws = as.numeric(gsub("[^0-9.-]", "", filename.split[3])),
    n = n,
    traj = filename.split[5],
    rho = abs(as.numeric(spear["estimate"])),
    p.value = as.numeric(spear["p.value"]),
    rho.excluded = abs(as.numeric(spear.excluded["estimate"])),
    p.value.excluded = as.numeric(spear.excluded["p.value"]),
    ranking = type
  )

  return(df)
}))



# Write the output
write_csv(agg, path = OUTPUT_FILE_PATH)

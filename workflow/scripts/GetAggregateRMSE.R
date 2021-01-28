#
# GetAggregateRMSE.R
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
  data <- read_csv(path, col_types = cols())

  error.exp <- sqrt(mean((log10(data$expected.exp) - log10(data$actual)) ^ 2, na.rm = T))
  error.power <- sqrt(mean((log10(data$expected.power) - log10(data$actual)) ^ 2, na.rm = T))

  # Specity the parameters of the file, including the embedding dimensions
  # and window size
  filename.split <- unlist(strsplit(basename(path), "_"))
  print(filename.split)
  case <- gsub("(-country)", "", filename.split[1])
  sizetype <- gsub("(size)", "", filename.split[2])
  traj <- filename.split[4]
  dim <- as.numeric(gsub("[^0-9.-]", "", filename.split[6]))
  ws <- as.numeric(gsub("[^0-9.-]", "", filename.split[7]))
  gamma <- as.numeric(gsub("[^0-9.-]|(.csv)", "", filename.split[8]))
  # Get the distnace metric used
  metric <- unlist(strsplit(path, "/"))[10]

  # Build the final dataframe
  df <- data.frame(
    traj, sizetype, case, dim, ws, gamma, metric, error.exp, error.power
  )

  return(df)
}))


# Write the output
write_csv(agg, path = OUTPUT_FILE_PATH)

#
# FormatRawDataToInstSentences.R
#
# author: Dakota Murray
#
# Converts the raw data into "sentence" format, meaning that for each individual,
# their various affiliation tokens are converted into a single "sentence" of tokens
# separated by spaces
#

library(dplyr)

# Parse command line argument
# First = Raw transition data
# 2 = The target scale, which here is simply used as the column name.
# last = Output file
args = commandArgs(trailingOnly=TRUE)

RAW_MOBILITY_PATH = first(args)
TARGET_SCALE = args[2]
OUTPUT_FILE_PATH = last(args)

mobility.raw = readr::read_csv(RAW_MOBILITY_PATH, col_types = readr::cols())

mobility.formatted = mobility.raw %>%
  rename(token = TARGET_SCALE) %>%
  group_by(cluster_id) %>%
  summarize(
    has_multiple_tokens = length(unique(token)) > 1,
    sentence = paste(token, collapse = " ")
  ) %>%
  filter(has_multiple_tokens) %>%
  select(cluster_id, sentence)

readr::write_csv(mobility.formatted, path = OUTPUT_FILE_PATH)

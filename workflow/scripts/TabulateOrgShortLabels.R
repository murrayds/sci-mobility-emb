#
# TabulateOrgShortLabels.R
#
# author: Dakota Murray
#
# Creates a supporting table detailing the full names used for
# shortened organization labels
#
library(dplyr)
library(xtable)

# Parse command line argument
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("--labels"), action="store", default=NA, type='character',
              help="Path to file containing organization short labels"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save the latex formatted table")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load the labels, and combine the names into a single field that makes
# the whole thing much easier to reshape
labels <- readr::read_csv(opt$labels, col_types = readr::cols()) %>%
  rowwise() %>%
  mutate(name = paste(c(short_name, full_name), collapse = ";")) %>%
  select(name)

# Pad the combined label strings with NA in the case that
# there is not an even number
label.names <- labels$name
length(label.names) <- prod(dim(matrix(label.names, ncol = 2)))

# Create a 2 column matrix from the combined and padded labels
label.mat <- matrix(label.names, ncol = 2)

# cast to a data frame, separate values
formatted <- as.data.frame(label.mat) %>%
  tidyr::separate(V1, sep = ";", into = c("short1", "full1")) %>%
  tidyr::separate(V2, sep = ";", into = c("short2", "full2"))

# Change the column names to something more appropriate
names(formatted) <- c("Short", "Full", "Short", "Full")

# Build the xtable object
tab <- xtable(
   formatted,
   align = c("l", "l", "l", "l", "l")
)

# print the xtable to a file
print.xtable(
  tab,
  type = "latex",
  size = "\\scriptsize", # set the font size to something very small
  include.rownames = FALSE, # necessary to prevent printing of row numbers
  file = opt$output
)

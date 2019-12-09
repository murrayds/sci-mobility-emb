#
# PlotGradientLegend.R
#
# author: Dakota Murray
#
# Plot a basic legend, all by itself, for use in the grid figure
#


library(ggplot2)
library(dplyr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save the legend")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Luckily, the cowplot package has a nice function for extracting the legend.
# We will just build a basic plot from a built-in dataset, and call the
# appropriate function
legend <- cowplot::get_legend(ggplot(diamonds, aes(clarity, color = x)) +
  geom_bar() +
  scale_color_gradientn(
    colours=c("white", "#7f8c8d"),
    name = "Frequency",
    breaks = c(0, 1, 2, 3, 4, 5),
    limits = c(0, 5),
    labels = function(x) { parse(text=paste0("10^", x)) },
    na.value=NA
  ) +
  theme(
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12)
  )
)

# Save the plot
ggsave(opt$output, legend)

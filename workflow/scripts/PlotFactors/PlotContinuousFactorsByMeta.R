#
# PlotContinuousMeta ByFactorsByMeta.R
#
# author: Dakota Murray
#
# Plot factors against continuous univeristy characteristics
#

# Plotting options
NUM_HEX_BINS = 20

REGRESSION_LINE_COLOR = "#c0392b"

# Plot dimensions
FIG_WIDTH = 3
FIG_HEIGHT = 3

library(ggplot2)
library(dplyr)
library(readr)
suppressPackageStartupMessages(require(optparse))

# Command line arguments
option_list = list(
  make_option(c("-i", "--input"), action="store", default=NA, type='character',
              help="Path to file containing model factor values"),
  make_option(c("--lookup"), action="store", default=NA, type='character',
              help="Path to file containing organization lookup info"),
  make_option(c("--carnegie"), action="store", default=NA, type='character',
              help="Path to file containing carnegie classification"),
  make_option(c("--unicw"), action="store", default=NA, type='character',
              help="Path to file containing university crosswalk"),
  make_option(c("--times"), action="store", default=NA, type='character',
              help="Path to file containing Times information"),
  make_option(c("--leiden"), action="store", default=NA, type='character',
              help="Path to file containing leiden information"),
  make_option(c("--sizes"), action="store", default=NA, type='character',
              help="Path to file containing sizes of organizations"),
  make_option(c("--toplot"), action="store", default=NA, type='character',
              help="Whether to plot pulling force ('pull') or gravitation potential ('potential')"),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Path to save output image")
) # end option_list
opt = parse_args(OptionParser(option_list=option_list))

# Load data
factors <- read_csv(opt$input, col_types = cols())

# Load the lookup file
lookup <- read_delim(opt$lookup, col_types = cols(), delim = "\t")

# Load the carnegie classifications
carnegie <- readxl::read_excel(opt$carnegie, sheet = "Data", trim_ws = T)

# Load the univeristy crosswalk table
cw <- read_csv(opt$unicw, col_types = cols())

# Load the leiden rankings
leiden <- read_csv(opt$leiden, col_types = cols())

times <- read_csv(opt$times, col_types = cols())

# Load the organization sizes
inst_sizes = readr::read_delim(opt$sizes, delim = "\t", col_types = cols()) %>%
  group_by(cwts_org_no) %>%
  summarize(
    count = mean(person_count)
  )

factors.ext <- factors %>%
  left_join(lookup, by = "cwts_org_no") %>%
  filter(country_iso_alpha == "USA" & org_type_code == "U") %>%
  left_join(cw, by = "cwts_org_no") %>%
  left_join(carnegie, by = c("cc_id" = "UNITID")) %>%
  left_join(leiden, by = "cwts_org_no") %>%
  left_join(times, by = "cwts_org_no") %>%
  left_join(inst_sizes, by = "cwts_org_no") %>%
  # Construct the factors
  mutate(
    # Log transform some of the main continuous variables
    s_i = log10(s_i),
    pubs = log10(impact_frac_p),
    gravity_potential = log10(gravity_potential),
    count = log10(count),
    research = recode(BASIC2018, `15` = "R1", `16` = "R2", `17` = "R3", .default = "Other"),
    urban = recode(LOCALE,
                   `11` = "City", `12` = "City", `13` = "City",
                   `21` = "Suburb", `22` = "Suburb", `23` = "Suburb",
                   .default = "Rural"),
    urban = factor(urban, levels = c("Rural", "Suburb", "City"))
  ) %>%
  arrange(desc(impact_frac_mncs)) %>%
  mutate(
    leiden_rank = ifelse(is.na(impact_frac_mncs), NA, row_number())
  ) %>%
  arrange(desc(total_score)) %>%
  mutate(
    times_rank = ifelse(is.na(total_score), NA, row_number())
  )

if (opt$toplot == "pull") {
  var.yaxis <- "s_i"
  varname.yaxis <- latex2exp::TeX("$\\log_{10}(s_{i})")
  var.compare <- "gravity_potential"
  varname.compare <- "Log10(gravity potential)"
} else if (opt$toplot == "potential") {
  var.yaxis <- "gravity_potential"
  varname.yaxis <- "Log10(gravity potential)"
  var.compare <- "s_i"
  varname.compare <- latex2exp::TeX("$\\log_{10}(s_{i})")
}

print(factors.ext %>% select(full_name, times_rank, leiden_rank))

count <- 0
breaks_fun <- function(x) {
  count <<- count + 1L

  # Setup indices that are different between the
  # plotting variables
  if (opt$toplot == "pull") {
    index.1 = c(0, 6)
  } else {
    index.1 = c(1, 7)
  }

  to_return <- switch(
    floor((count + 1) / 2),
    c(1, 4),
    c(1, 400),
    c(1, 400),
    c(0, 400),
    c(0, 2e+06),
    c(0, 1e+05),
    c(0, 6e+4),
    c(0, 20000),
    c(0, 600),
    c(0, 100),
    c(0, 150),
    c(0, 250)
  )
  return(to_return)
}

# Build the plot
plot <- factors.ext %>%
  rename(measure = var.yaxis,
         to.compare = var.compare) %>%
  # Select only variables that we will be plotting
  select(count, leiden_rank, times_rank, FALLENR17, GRFTF17, GRCIP4PR,
         HUM_RSD, OTHER_RSD, STEM_RSD, SOCSC_RSD,
         `S&ER&D`, `NONS&ER&D`, measure) %>%
  na.omit() %>% # remove NA values
  tidyr::gather(key, value,
                count, leiden_rank, times_rank, FALLENR17, GRFTF17, GRCIP4PR,
                HUM_RSD, OTHER_RSD, STEM_RSD, SOCSC_RSD,
                `S&ER&D`, `NONS&ER&D`) %>%
  mutate(
    key = factor(key,
                 levels = c("count", "times_rank", "leiden_rank", "GRCIP4PR",
                            "S&ER&D", "NONS&ER&D", "FALLENR17", "GRFTF17",
                            "STEM_RSD", "SOCSC_RSD", "HUM_RSD", "OTHER_RSD"),
                 labels = c("Log10(#authors)", "Times Rank", "Leiden Rank",  "#Doctoral Fields",
                            "S&E $ (1000's)", "Non S&E $ (1000's)", "Total Enrollment", "Graduate Enrollment",
                            "#STEM PhDs", "#Soc. Sci. PhDs", "#Humanities PhDs", "#Other PhDs")
                )
  ) %>%
  ggplot(aes(x = value, y = measure)) +
  geom_point(alpha = 0.75, size = 1) +
  facet_wrap(~key, scale = "free_x", nrow = 3) +
  stat_smooth(method = "loess",
              formula = y ~ x,
              color = "dodgerblue4",
              size = 0.5,
              fullrange = T) +
  stat_smooth(method = "lm",
              formula = y ~ x,
              color = "firebrick4",
              size = 1,
              fullrange = T) +
  ggpmisc::stat_poly_eq(formula = y ~ x,
                        geom = "text_npc",
                        aes(label = paste(..rr.label.., sep = "~~~")),
                        parse=TRUE,
                        label.x.npc = 0.05,
                        label.y.npc = 0.05,
                        rr.digits = 1,
                        size = 3,
                        color = "firebrick4"
  ) +
  scale_x_continuous(
    breaks = breaks_fun,
    expand = c(0.1, 0)
  ) +
  scale_y_continuous(
    breaks = c(0, 4, 8),
    labels = function(x) { parse(text=paste0("10^", x)) },
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = "Helvetica", size = 12),
    axis.title = element_text(size = 14, face = "bold"),
    axis.title.x = element_blank(),
    panel.spacing = unit(0.2, "lines"),
    panel.spacing.x = unit(0.5, "lines"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_rect(size = 0.5, fill = NA),
    strip.text = element_text(face = "bold"),
    axis.ticks = element_line()
  ) +
  ylab(varname.yaxis)


# Save the plot
ggsave(opt$output, plot, height = 6, width = 8)

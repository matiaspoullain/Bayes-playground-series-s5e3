library(brms)
library(bayesplot)
library(ggplot2)
library(data.table)
source("src/plot_theme.R")

bayesplot::color_scheme_set(c("grey80", "grey80", "grey80", rainfall_accent, rainfall_accent_dark, rainfall_accent_dark))

fit <- readRDS("models/fit_full.rds")
dir.create("tables_figures/diagnostics", showWarnings = FALSE, recursive = TRUE)

summ <- summary(fit)
diagnostics <- rbindlist(list(
  as.data.table(summ$fixed, keep.rownames = "term"),
  as.data.table(summ$spec_pars, keep.rownames = "term")
))[, .(term, Rhat, Bulk_ESS, Tail_ESS)]

divergences <- as.data.table(nuts_params(fit))[Parameter == "divergent__", sum(Value)]
diagnostics_summary <- rbindlist(list(
  diagnostics,
  data.table(term = "TOTAL_DIVERGENCES", Rhat = NA, Bulk_ESS = NA, Tail_ESS = divergences)
))

fwrite(diagnostics_summary, "tables_figures/diagnostics/rhat_ess_summary.csv")
print(diagnostics_summary)

cat("\nMax Rhat:", max(diagnostics$Rhat, na.rm = TRUE), "(target: < 1.01)\n")
cat("Min Bulk ESS:", min(diagnostics$Bulk_ESS, na.rm = TRUE), "(target: > 400)\n")
cat("Divergent transitions:", divergences, "(target: 0)\n")

pp_check(fit, type = "bars", ndraws = 200) +
  labs(
    title = "Posterior predictive check",
    subtitle = "Observed vs. model-simulated 0/1 rainfall counts (200 draws)"
  ) +
  theme_rainfall()
ggsave("tables_figures/diagnostics/pp_check_bars.png", width = 7, height = 6, bg = "white")

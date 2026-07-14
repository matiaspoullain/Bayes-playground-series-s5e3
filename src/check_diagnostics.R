library(brms)
library(bayesplot)
library(ggplot2)
source("src/plot_theme.R")

bayesplot::color_scheme_set(c("grey80", "grey80", "grey80", rainfall_accent, rainfall_accent_dark, rainfall_accent_dark))

fit <- readRDS("models/fit_full.rds")
dir.create("tables_figures/diagnostics", showWarnings = FALSE, recursive = TRUE)

summ <- summary(fit)
diagnostics <- rbind(
  data.frame(summ$fixed, term = rownames(summ$fixed)),
  data.frame(summ$spec_pars, term = rownames(summ$spec_pars))
)
diagnostics <- diagnostics[, c("term", "Rhat", "Bulk_ESS", "Tail_ESS")]

divergences <- sum(subset(nuts_params(fit), Parameter == "divergent__")$Value)
diagnostics_summary <- rbind(
  diagnostics,
  data.frame(term = "TOTAL_DIVERGENCES", Rhat = NA, Bulk_ESS = NA, Tail_ESS = divergences)
)

write.csv(diagnostics_summary, "tables_figures/diagnostics/rhat_ess_summary.csv", row.names = FALSE)
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

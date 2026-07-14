library(brms)
library(ggplot2)
source("src/plot_theme.R")

fit <- readRDS("models/fit_full.rds")
dir.create("tables_figures/report", showWarnings = FALSE, recursive = TRUE)

# --- Table + Figure 1: odds ratios (exp of fixed-effect coefficients), 95% CrI ---

fixef_draws <- as.data.frame(fixef(fit, summary = TRUE))
fixef_draws$term <- rownames(fixef_draws)
fixef_draws <- fixef_draws[fixef_draws$term != "Intercept", ]

odds_ratios <- data.frame(
  term = fixef_draws$term,
  odds_ratio = exp(fixef_draws$Estimate),
  or_lower_95 = exp(fixef_draws$Q2.5),
  or_upper_95 = exp(fixef_draws$Q97.5)
)
write.csv(odds_ratios, "tables_figures/report/odds_ratios_summary.csv", row.names = FALSE)
print(odds_ratios)

ggplot(odds_ratios, aes(y = reorder(term, odds_ratio), x = odds_ratio)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = rainfall_grey, linewidth = 0.5) +
  geom_pointrange(
    aes(xmin = or_lower_95, xmax = or_upper_95),
    colour = rainfall_accent_dark, linewidth = 0.9, size = 1
  ) +
  labs(
    x = "Odds ratio (per 1 SD increase, or per unit for sin/cos terms)", y = NULL,
    title = "Rainfall odds ratios by predictor",
    subtitle = "95% credible interval; dashed line marks no effect (OR = 1)"
  ) +
  theme_rainfall()
ggsave("tables_figures/report/odds_ratios_forest_plot.png", width = 9, height = 6, bg = "white")

# --- Figure 2: day-of-year seasonal smooth ---

ce_day <- conditional_effects(fit, effects = "day")
ce_day_df <- ce_day[["day"]]

seasonal_plot <- ggplot(ce_day_df, aes(x = effect1__, y = estimate__)) +
  geom_ribbon(aes(ymin = lower__, ymax = upper__), fill = rainfall_accent, alpha = 0.18) +
  geom_line(colour = rainfall_accent_dark, linewidth = 1) +
  labs(
    x = "Day of year", y = "P(rainfall)",
    title = "Seasonal effect of day-of-year on rainfall probability",
    subtitle = "Posterior mean and 95% credible band from the cyclic smooth term"
  ) +
  theme_rainfall()
ggsave(
  "tables_figures/report/seasonal_effect_day.png",
  seasonal_plot, width = 9, height = 6, bg = "white"
)

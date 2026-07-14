library(brms)
library(ggplot2)
library(posterior)
library(ggdist)
library(data.table)
source("src/plot_theme.R")

fit <- readRDS("models/fit_full.rds")
dir.create("tables_figures/report", showWarnings = FALSE, recursive = TRUE)

# --- Table + Figure 1: odds ratios (exp of fixed-effect coefficients), 95% CrI ---
# Uses the actual posterior draws (not just the summary) so the plot can show the
# full posterior density as a "shadow" behind each point + interval, via ggdist's
# half-eye geom — not just a single summary pointrange.

fixef_terms <- c(
  "dewpoint_depression_z", "humidity_z", "cloud_z", "sunshine_z",
  "windspeed_z", "winddirection_sin", "winddirection_cos"
)
draws_df <- as_draws_df(fit)

posterior_or_long <- rbindlist(lapply(fixef_terms, function(term) {
  data.table(term = term, odds_ratio = exp(draws_df[[paste0("b_", term)]]))
}))

summarize_or_draws <- function(long_dt) {
  long_dt[, .(
    odds_ratio = mean(odds_ratio),
    or_lower_95 = quantile(odds_ratio, 0.025),
    or_upper_95 = quantile(odds_ratio, 0.975)
  ), by = term]
}

odds_ratios <- summarize_or_draws(posterior_or_long)
fwrite(odds_ratios, "tables_figures/report/odds_ratios_summary.csv")
print(odds_ratios)

term_order <- odds_ratios[order(odds_ratio), term]
posterior_or_long[, term := factor(term, levels = term_order)]

ggplot(posterior_or_long, aes(y = term, x = odds_ratio)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = rainfall_grey, linewidth = 0.5) +
  stat_halfeye(
    .width = 0.95, point_interval = "mean_qi",
    fill = rainfall_accent, slab_alpha = 0.55,
    colour = rainfall_accent_dark, linewidth = 1.1, point_size = 3
  ) +
  labs(
    x = "Odds ratio (per 1 SD increase, or per unit for sin/cos terms)", y = NULL,
    title = "Rainfall odds ratios by predictor",
    subtitle = "Posterior distribution, mean & 95% CrI\n(dashed line marks no effect, OR = 1)"
  ) +
  theme_rainfall()
ggsave("tables_figures/report/odds_ratios_forest_plot.png", width = 9, height = 6, bg = "white")

# --- Table + Figure: same odds ratios, converted to the raw (unstandardized) scale ---
# Standardization is an affine transform (x_z = (x - mean) / sd), so the raw-scale
# coefficient is simply beta_z / sd, and the raw-scale OR is exp(beta_z / sd) — a
# monotonic, per-draw rescaling of the same posterior, no refit needed.

std_stats <- readRDS("models/fit_full_standardization_stats.rds")

raw_unit_labels <- c(
  dewpoint_depression_z = "dewpoint_depression (°C)",
  humidity_z = "humidity (percentage point)",
  cloud_z = "cloud (percentage point)",
  sunshine_z = "sunshine (hour)",
  windspeed_z = "windspeed (native unit, undocumented)"
)

posterior_or_raw_long <- rbindlist(lapply(names(raw_unit_labels), function(term) {
  var <- sub("_z$", "", term)
  sd_x <- std_stats[[var]]$sd
  data.table(
    term = raw_unit_labels[[term]],
    odds_ratio = exp(draws_df[[paste0("b_", term)]] / sd_x)
  )
}))

odds_ratios_raw <- summarize_or_draws(posterior_or_raw_long)
fwrite(odds_ratios_raw, "tables_figures/report/odds_ratios_raw_scale_summary.csv")
print(odds_ratios_raw)

raw_term_order <- odds_ratios_raw[order(odds_ratio), term]
posterior_or_raw_long[, term := factor(term, levels = raw_term_order)]

ggplot(posterior_or_raw_long, aes(y = term, x = odds_ratio)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = rainfall_grey, linewidth = 0.5) +
  stat_halfeye(
    .width = 0.95, point_interval = "mean_qi",
    fill = rainfall_accent, slab_alpha = 0.55,
    colour = rainfall_accent_dark, linewidth = 1.1, point_size = 3
  ) +
  labs(
    x = "Odds ratio (per 1 raw unit increase)", y = NULL,
    title = "Rainfall odds ratios by predictor (raw scale)",
    subtitle = "Posterior distribution, mean & 95% CrI\n(dashed line marks no effect, OR = 1)"
  ) +
  theme_rainfall()
ggsave("tables_figures/report/odds_ratios_forest_plot_raw_scale.png", width = 9, height = 6, bg = "white")

# --- Figure 2: day-of-year seasonal smooth ---

ce_day <- conditional_effects(fit, effects = "day")
ce_day_dt <- as.data.table(ce_day[["day"]])

seasonal_plot <- ggplot(ce_day_dt, aes(x = effect1__, y = estimate__)) +
  geom_ribbon(aes(ymin = lower__, ymax = upper__), fill = rainfall_accent, alpha = 0.18) +
  geom_line(colour = rainfall_accent_dark, linewidth = 1) +
  scale_x_continuous(breaks = seq(0, 360, by = 30), minor_breaks = seq(15, 345, by = 30)) +
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

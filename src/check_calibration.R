source("src/metrics.R")
library(ggplot2)
library(data.table)
source("src/plot_theme.R")

oof <- fread("tables_figures/cv/oof_predictions.csv")
dir.create("tables_figures/calibration", showWarnings = FALSE, recursive = TRUE)

oof[, bin := cut(oof_pred_prob, breaks = seq(0, 1, by = 0.1), include.lowest = TRUE, labels = FALSE)]

reliability <- oof[, .(
  observed_rate = mean(rainfall),
  mean_predicted = mean(oof_pred_prob),
  n = .N
), by = bin][order(bin)]

overall_auc <- auc(oof$rainfall, oof$oof_pred_prob)
overall_brier <- brier_score(oof$rainfall, oof$oof_pred_prob)

cat("Pooled out-of-fold AUC:", overall_auc, "\n")
cat("Pooled out-of-fold Brier score:", overall_brier, "\n")

fwrite(
  data.table(metric = c("auc", "brier_score"), value = c(overall_auc, overall_brier)),
  "tables_figures/calibration/calibration_summary.csv"
)

ggplot(reliability, aes(x = mean_predicted, y = observed_rate)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = rainfall_grey, linewidth = 0.5) +
  geom_line(colour = rainfall_accent, linewidth = 0.8) +
  geom_point(colour = rainfall_accent_dark, fill = "white", shape = 21, size = 3.5, stroke = 1.2) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  scale_x_continuous(breaks = seq(0, 1, by = 0.1)) +
  scale_y_continuous(breaks = seq(0, 1, by = 0.1)) +
  labs(
    x = "Mean predicted probability (per 10-point-wide bin)", y = "Observed rainfall rate",
    title = "Reliability diagram",
    subtitle = "Out-of-fold predictions (leave-one-year-out CV), 10 equally-spaced bins"
  ) +
  theme_rainfall()
ggsave("tables_figures/calibration/reliability_diagram.png", width = 7, height = 7, bg = "white")

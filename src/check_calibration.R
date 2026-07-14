source("src/metrics.R")
library(ggplot2)
source("src/plot_theme.R")

oof <- read.csv("tables_figures/cv/oof_predictions.csv")
dir.create("tables_figures/calibration", showWarnings = FALSE, recursive = TRUE)

oof$decile <- cut(oof$oof_pred_prob, breaks = quantile(oof$oof_pred_prob, probs = seq(0, 1, 0.1)),
                   include.lowest = TRUE, labels = FALSE)

reliability <- aggregate(
  cbind(observed_rate = rainfall, mean_predicted = oof_pred_prob) ~ decile,
  data = oof, FUN = mean
)

overall_auc <- auc(oof$rainfall, oof$oof_pred_prob)
overall_brier <- brier_score(oof$rainfall, oof$oof_pred_prob)

cat("Pooled out-of-fold AUC:", overall_auc, "\n")
cat("Pooled out-of-fold Brier score:", overall_brier, "\n")

write.csv(
  data.frame(metric = c("auc", "brier_score"), value = c(overall_auc, overall_brier)),
  "tables_figures/calibration/calibration_summary.csv", row.names = FALSE
)

ggplot(reliability, aes(x = mean_predicted, y = observed_rate)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = rainfall_grey, linewidth = 0.5) +
  geom_line(colour = rainfall_accent, linewidth = 0.8) +
  geom_point(colour = rainfall_accent_dark, fill = "white", shape = 21, size = 3.5, stroke = 1.2) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    x = "Mean predicted probability (per decile bin)", y = "Observed rainfall rate",
    title = "Reliability diagram",
    subtitle = "Out-of-fold predictions (leave-one-year-out CV), 10 bins"
  ) +
  theme_rainfall()
ggsave("tables_figures/calibration/reliability_diagram.png", width = 7, height = 7, bg = "white")

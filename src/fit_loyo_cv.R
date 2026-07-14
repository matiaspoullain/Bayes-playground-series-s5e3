source("src/features.R")
source("src/model_spec.R")
source("src/metrics.R")
library(brms)
library(data.table)

train_raw <- fread("data/raw/train.csv")
train_raw <- engineer_rainfall_features(train_raw)

folds <- make_year_folds(train_raw$id)
predictor_cols <- c("dewpoint_depression", "humidity", "cloud", "sunshine", "windspeed")

dir.create("models", showWarnings = FALSE)
dir.create("tables_figures/cv", showWarnings = FALSE, recursive = TRUE)

fold_summaries <- list()
oof_predictions <- data.table(
  id = train_raw$id, rainfall = train_raw$rainfall, oof_pred_prob = NA_real_
)

for (held_out_year in sort(unique(folds))) {
  fit_data_raw <- train_raw[folds != held_out_year]
  holdout_data_raw <- train_raw[folds == held_out_year]

  std <- standardize_predictors(fit_data_raw, predictor_cols)
  fit_data <- std$data
  holdout_data <- standardize_predictors(holdout_data_raw, predictor_cols, stats = std$stats)$data

  fit <- brm(
    formula = rainfall_formula(),
    data = fit_data,
    family = rainfall_family(),
    prior = rainfall_priors(),
    backend = "cmdstanr",
    chains = 4, cores = 4, iter = 2000, warmup = 1000,
    control = list(adapt_delta = 0.95),
    seed = 1
  )

  saveRDS(fit, sprintf("models/cv_year_%d.rds", held_out_year))

  pred_draws <- posterior_epred(fit, newdata = holdout_data, allow_new_levels = TRUE)
  pred_prob <- colMeans(pred_draws)
  oof_predictions[folds == held_out_year, oof_pred_prob := pred_prob]

  summ <- summary(fit)
  rhats <- c(summ$fixed[, "Rhat"], summ$spec_pars[, "Rhat"])
  ess_bulk <- c(summ$fixed[, "Bulk_ESS"], summ$spec_pars[, "Bulk_ESS"])
  divergences <- as.data.table(nuts_params(fit))[Parameter == "divergent__", sum(Value)]

  key <- as.character(held_out_year)
  fold_summaries[[key]] <- data.table(
    held_out_year = held_out_year,
    auc = auc(holdout_data$rainfall, pred_prob),
    brier = brier_score(holdout_data$rainfall, pred_prob),
    max_rhat = max(rhats),
    min_bulk_ess = min(ess_bulk),
    divergences = divergences
  )

  cat(sprintf(
    "Year %d held out: AUC=%.4f Brier=%.4f max_Rhat=%.4f min_ESS=%.0f divergences=%d\n",
    held_out_year, fold_summaries[[key]]$auc, fold_summaries[[key]]$brier,
    fold_summaries[[key]]$max_rhat, fold_summaries[[key]]$min_bulk_ess, divergences
  ))
}

cv_summary <- rbindlist(fold_summaries)
fwrite(cv_summary, "tables_figures/cv/cv_summary.csv")
fwrite(oof_predictions, "tables_figures/cv/oof_predictions.csv")

cat("\nMean per-year AUC:", mean(cv_summary$auc), "SD:", sd(cv_summary$auc), "\n")
cat("Pooled out-of-fold AUC:", auc(oof_predictions$rainfall, oof_predictions$oof_pred_prob), "\n")

source("src/features.R")
library(brms)

fit <- readRDS("models/fit_full.rds")
stats <- readRDS("models/fit_full_standardization_stats.rds")
train_raw <- read.csv("data/raw/train.csv")
test_raw <- read.csv("data/raw/test.csv")

predictor_cols <- c("dewpoint_depression", "humidity", "cloud", "sunshine", "windspeed")
pred_prob <- numeric(nrow(test_raw))

# test.csv has 1 missing `winddirection` value (train.csv has none). Rather than
# imputing a single point value — which would collapse our uncertainty about the
# true wind direction to zero — we marginalize: for each posterior draw, average
# the predicted probability over winddirection's full empirical distribution from
# the training set, then average across draws. This propagates the missingness as
# genuine predictive uncertainty instead of pretending we know the value.
missing_wd <- is.na(test_raw$winddirection)
n_missing <- sum(missing_wd)
if (n_missing > 0) {
  cat(sprintf(
    "%d test row(s) missing winddirection — marginalizing over the training winddirection distribution (%d values) instead of imputing a point value\n",
    n_missing, nrow(train_raw)
  ))
}

complete_idx <- which(!missing_wd)
test_complete <- engineer_rainfall_features(test_raw[complete_idx, , drop = FALSE])
test_complete_std <- standardize_predictors(test_complete, predictor_cols, stats = stats)$data
pred_draws_complete <- posterior_epred(fit, newdata = test_complete_std)
pred_prob[complete_idx] <- colMeans(pred_draws_complete)

incomplete_idx <- which(missing_wd)
for (i in incomplete_idx) {
  row_expanded <- test_raw[rep(i, nrow(train_raw)), , drop = FALSE]
  row_expanded$winddirection <- train_raw$winddirection
  row_expanded <- engineer_rainfall_features(row_expanded)
  row_expanded_std <- standardize_predictors(row_expanded, predictor_cols, stats = stats)$data

  draws <- posterior_epred(fit, newdata = row_expanded_std)  # n_draws x n_train_rows
  marginal_draws <- rowMeans(draws)  # average over winddirection, per posterior draw
  pred_prob[i] <- mean(marginal_draws)  # then average over draws
}

stopifnot("Predicted probabilities contain NA/missing values" = !anyNA(pred_prob))

submission <- data.frame(id = test_raw$id, rainfall = pred_prob)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write.csv(submission, "data/processed/submission.csv", row.names = FALSE)

cat("Submission written: data/processed/submission.csv\n")
cat("Predicted probability range: [", min(pred_prob), ",", max(pred_prob), "]\n")
cat("Predicted probability mean:", mean(pred_prob), "\n")

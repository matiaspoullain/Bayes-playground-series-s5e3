source("src/features.R")
source("src/model_spec.R")
library(brms)

train_raw <- read.csv("data/raw/train.csv")
train_raw <- engineer_rainfall_features(train_raw)

predictor_cols <- c("dewpoint_depression", "humidity", "cloud", "sunshine", "windspeed")
std <- standardize_predictors(train_raw, predictor_cols)
train <- std$data

fit <- brm(
  formula = rainfall_formula(),
  data = train,
  family = rainfall_family(),
  prior = rainfall_priors(),
  backend = "cmdstanr",
  chains = 4, cores = 4, iter = 2000, warmup = 1000,
  control = list(adapt_delta = 0.95),
  seed = 1
)

print(summary(fit))

dir.create("models", showWarnings = FALSE)
saveRDS(fit, "models/fit_full.rds")
saveRDS(std$stats, "models/fit_full_standardization_stats.rds")

source("src/features.R")
source("src/model_spec.R")
library(brms)
library(data.table)

train <- fread("data/raw/train.csv")
train <- engineer_rainfall_features(train)
std <- standardize_predictors(
  train,
  predictor_cols = c("dewpoint_depression", "humidity", "cloud", "sunshine", "windspeed")
)
train <- std$data

fit_prior <- brm(
  formula = rainfall_formula(),
  data = train,
  family = rainfall_family(),
  prior = rainfall_priors(),
  sample_prior = "only",
  backend = "cmdstanr",
  chains = 2, iter = 500, warmup = 250,
  seed = 1
)

prior_probs <- posterior_epred(fit_prior, ndraws = 200)
cat("Prior predictive probability range: [", min(prior_probs), ",", max(prior_probs), "]\n")
cat("Prior predictive probability median:", median(prior_probs), "\n")
cat("Observed base rain rate:", mean(train$rainfall), "\n")

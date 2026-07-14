source(file.path("..", "..", "src", "features.R"))

test_that("engineer_rainfall_features computes dewpoint depression and circular wind encoding", {
  df <- data.frame(
    temparature = c(20, 15), dewpoint = c(15, 15), winddirection = c(0, 90)
  )
  result <- engineer_rainfall_features(df)

  expect_equal(result$dewpoint_depression, c(5, 0))
  expect_equal(result$winddirection_sin, c(0, 1), tolerance = 1e-8)
  expect_equal(result$winddirection_cos, c(1, 0), tolerance = 1e-8)
})

test_that("standardize_predictors z-scores columns and returns reusable stats", {
  df <- data.frame(x = c(1, 2, 3, 4, 5))
  out <- standardize_predictors(df, predictor_cols = "x")

  expect_equal(mean(out$data$x_z), 0, tolerance = 1e-8)
  expect_equal(sd(out$data$x_z), 1, tolerance = 1e-8)
  expect_equal(out$stats$x$mean, 3)
})

test_that("standardize_predictors reuses supplied stats instead of recomputing", {
  train <- data.frame(x = c(1, 2, 3, 4, 5))
  train_out <- standardize_predictors(train, predictor_cols = "x")

  new_data <- data.frame(x = c(3))
  new_out <- standardize_predictors(new_data, predictor_cols = "x", stats = train_out$stats)

  expect_equal(new_out$data$x_z, 0)  # 3 is the training mean, so z-score is 0
})

test_that("make_year_folds assigns consecutive id blocks to the same year", {
  ids <- c(0, 1, 364, 365, 366, 729, 730, 2189)
  folds <- make_year_folds(ids)

  expect_equal(folds, c(0, 0, 0, 1, 1, 1, 2, 5))
})

test_that("make_year_folds produces exactly 6 years for the full id range of this dataset", {
  ids <- 0:2189
  folds <- make_year_folds(ids)

  expect_equal(sort(unique(folds)), 0:5)
  expect_true(all(table(folds) == 365))
})

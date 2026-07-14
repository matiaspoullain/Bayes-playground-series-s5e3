engineer_rainfall_features <- function(df) {
  df$dewpoint_depression <- df$temparature - df$dewpoint
  df$winddirection_sin <- sin(2 * pi * df$winddirection / 360)
  df$winddirection_cos <- cos(2 * pi * df$winddirection / 360)
  df
}

standardize_predictors <- function(df, predictor_cols, stats = NULL) {
  if (is.null(stats)) {
    stats <- list()
    for (col in predictor_cols) {
      stats[[col]] <- list(mean = mean(df[[col]]), sd = sd(df[[col]]))
    }
  }

  for (col in predictor_cols) {
    z_col <- paste0(col, "_z")
    df[[z_col]] <- (df[[col]] - stats[[col]]$mean) / stats[[col]]$sd
  }

  list(data = df, stats = stats)
}

make_year_folds <- function(id, rows_per_year = 365) {
  id %/% rows_per_year
}

library(data.table)

engineer_rainfall_features <- function(df) {
  dt <- as.data.table(df)
  dt[, `:=`(
    dewpoint_depression = temparature - dewpoint,
    winddirection_sin = sin(2 * pi * winddirection / 360),
    winddirection_cos = cos(2 * pi * winddirection / 360)
  )]
  dt[]
}

standardize_predictors <- function(df, predictor_cols, stats = NULL) {
  dt <- as.data.table(df)

  if (is.null(stats)) {
    stats <- setNames(
      lapply(predictor_cols, function(col) list(mean = mean(dt[[col]]), sd = sd(dt[[col]]))),
      predictor_cols
    )
  }

  for (col in predictor_cols) {
    set(dt, j = paste0(col, "_z"), value = (dt[[col]] - stats[[col]]$mean) / stats[[col]]$sd)
  }

  list(data = dt[], stats = stats)
}

make_year_folds <- function(id, rows_per_year = 365) {
  id %/% rows_per_year
}

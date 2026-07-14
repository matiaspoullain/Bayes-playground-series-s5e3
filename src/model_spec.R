library(brms)

rainfall_formula <- function() {
  bf(
    rainfall ~ 1 + dewpoint_depression_z + humidity_z + cloud_z + sunshine_z +
      windspeed_z + winddirection_sin + winddirection_cos +
      s(day, bs = "cc")
  )
}

rainfall_family <- function() {
  bernoulli(link = "logit")
}

rainfall_priors <- function() {
  c(
    set_prior("normal(1.1, 1)", class = "Intercept"),
    set_prior("normal(-0.5, 1)", class = "b", coef = "dewpoint_depression_z"),
    set_prior("normal(0.7, 1)", class = "b", coef = "humidity_z"),
    set_prior("normal(1, 1)", class = "b", coef = "cloud_z"),
    set_prior("normal(-0.8, 1)", class = "b", coef = "sunshine_z"),
    set_prior("normal(0.2, 1)", class = "b", coef = "windspeed_z"),
    set_prior("normal(0.1, 1)", class = "b", coef = "winddirection_sin"),
    set_prior("normal(0, 1)", class = "b", coef = "winddirection_cos")
  )
}

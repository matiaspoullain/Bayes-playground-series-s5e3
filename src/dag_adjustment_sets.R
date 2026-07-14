library(dagitty)

# This DAG mirrors the one in README.md exactly (same nodes, same edges) — it's
# the same causal story, just written in dagitty syntax so we can ask it a
# question we can't easily answer by eye: given this DAG, what set(s) of
# covariates does formal backdoor-path analysis say are needed to get an
# unconfounded estimate of each retained predictor's *direct* effect on
# `rainfall`? We compare that answer against the predictor set we chose by
# hand-reasoning through the DAG.

g <- dagitty('
dag {
  day_of_year -> pressure
  day_of_year -> maxtemp
  day_of_year -> mintemp
  day_of_year -> temparature
  day_of_year -> dewpoint
  day_of_year -> windspeed
  day_of_year -> winddirection
  day_of_year -> rainfall

  maxtemp -> dewpoint_depression
  mintemp -> dewpoint_depression
  temparature -> dewpoint_depression
  dewpoint -> dewpoint_depression

  dewpoint_depression -> humidity
  pressure -> humidity
  pressure -> cloud
  humidity -> cloud
  cloud -> sunshine

  dewpoint_depression -> rainfall
  humidity -> rainfall
  cloud -> rainfall
  sunshine -> rainfall
  windspeed -> rainfall
  winddirection -> rainfall
  windspeed -> humidity
  winddirection -> cloud
}
')

chosen_predictors <- c(
  "dewpoint_depression", "humidity", "cloud", "sunshine",
  "windspeed", "winddirection", "day_of_year"
)
excluded_variables <- c("pressure", "maxtemp", "mintemp", "temparature", "dewpoint")

cat("=== Adjustment sets for the DIRECT effect of each retained predictor on rainfall ===\n\n")

exposures <- c("dewpoint_depression", "humidity", "cloud", "sunshine", "windspeed", "winddirection", "day_of_year")

for (exposure in exposures) {
  cat(sprintf("--- Exposure: %s -> rainfall (direct effect) ---\n", exposure))
  sets <- adjustmentSets(g, exposure = exposure, outcome = "rainfall", effect = "direct")
  if (length(sets) == 0) {
    cat("  No adjustment needed (no open backdoor paths).\n")
  } else {
    for (s in sets) cat("  {", paste(s, collapse = ", "), "}\n")
  }
  cat("\n")
}

cat("=== Adjustment set for the joint direct effect of the whole chosen predictor set ===\n\n")
joint_sets <- adjustmentSets(g, exposure = exposures, outcome = "rainfall", effect = "direct")
if (length(joint_sets) == 0) {
  cat("No additional adjustment needed beyond the chosen predictors themselves.\n")
} else {
  for (s in joint_sets) cat("  {", paste(s, collapse = ", "), "}\n")
}

cat("\n=== Comparison against the predictor set we actually chose ===\n")
cat("Chosen predictors:  ", paste(chosen_predictors, collapse = ", "), "\n")
cat("Excluded variables: ", paste(excluded_variables, collapse = ", "), "\n")

all_required <- unique(unlist(joint_sets))
extra_required <- setdiff(all_required, chosen_predictors)
cat("\nVariables dagitty says are required beyond our chosen set: ",
    if (length(extra_required) == 0) "none" else paste(extra_required, collapse = ", "), "\n")

cat("\n=== Is each excluded variable ever UNAVOIDABLE (in every alternative set for some exposure)? ===\n")
cat("(vs. merely appearing as one substitutable option among several valid sets)\n\n")
for (v in excluded_variables) {
  in_every_set_for_some_exposure <- any(sapply(exposures, function(e) {
    s <- adjustmentSets(g, exposure = e, outcome = "rainfall", effect = "direct")
    length(s) > 0 && all(sapply(s, function(set) v %in% set))
  }))
  in_some_set_for_some_exposure <- any(sapply(exposures, function(e) {
    s <- adjustmentSets(g, exposure = e, outcome = "rainfall", effect = "direct")
    any(sapply(s, function(set) v %in% set))
  }))
  cat(sprintf(
    "  %-14s unavoidable for some exposure: %-5s | appears as a substitutable alternative: %s\n",
    v, in_every_set_for_some_exposure, in_some_set_for_some_exposure
  ))
}

auc <- function(actual, predicted_prob) {
  pos <- predicted_prob[actual == 1]
  neg <- predicted_prob[actual == 0]

  ranks <- rank(c(pos, neg))
  n_pos <- length(pos)
  n_neg <- length(neg)

  sum_pos_ranks <- sum(ranks[1:n_pos])
  u_statistic <- sum_pos_ranks - n_pos * (n_pos + 1) / 2

  u_statistic / (n_pos * n_neg)
}

brier_score <- function(actual, predicted_prob) {
  mean((predicted_prob - actual)^2)
}

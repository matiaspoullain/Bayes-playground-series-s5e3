library(ggplot2)
library(data.table)
source("src/plot_theme.R")

train <- fread("data/raw/train.csv")

vars <- c(
  "rainfall", "cloud", "sunshine", "humidity", "windspeed",
  "dewpoint", "maxtemp", "temparature", "mintemp", "pressure", "winddirection"
)
cor_mat <- cor(as.matrix(train[, ..vars]))

cor_dt <- melt(
  as.data.table(cor_mat, keep.rownames = "var1"),
  id.vars = "var1", variable.name = "var2", value.name = "r"
)
cor_dt[, `:=`(
  var1 = factor(var1, levels = vars),
  var2 = factor(var2, levels = rev(vars))
)]

dir.create("tables_figures/eda", showWarnings = FALSE, recursive = TRUE)

p <- ggplot(cor_dt, aes(x = var1, y = var2, fill = r)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.2f", r)), size = 3.1, colour = "grey15") +
  scale_fill_gradient2(
    low = "#B23A48", mid = "white", high = rainfall_accent_dark,
    midpoint = 0, limits = c(-1, 1), name = "Pearson r"
  ) +
  labs(
    x = NULL, y = NULL,
    title = "Correlation matrix: all raw predictors and rainfall",
    subtitle = "Pearson r (point-biserial for correlations involving the binary `rainfall` target)"
  ) +
  coord_fixed() +
  theme_rainfall() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )
ggsave("tables_figures/eda/correlation_matrix.png", p, width = 9, height = 8, bg = "white")

cat("Saved tables_figures/eda/correlation_matrix.png\n")

library(ggplot2)

rainfall_accent <- "#1B6CA8"
rainfall_accent_dark <- "#0D3B66"
rainfall_grey <- "grey45"

theme_rainfall <- function(base_size = 13) {
  theme_bw(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      legend.background = element_rect(fill = "white", colour = NA),
      legend.key = element_rect(fill = "white", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey88", linewidth = 0.3),
      panel.border = element_rect(colour = "grey70", fill = NA, linewidth = 0.6),
      strip.background = element_rect(fill = "grey93", colour = "grey70"),
      strip.text = element_text(face = "bold", colour = "grey20"),
      plot.title = element_text(face = "bold", size = rel(1.15), colour = "grey10", margin = margin(b = 6)),
      plot.subtitle = element_text(colour = "grey35", margin = margin(b = 10)),
      plot.caption = element_text(colour = "grey50", size = rel(0.75)),
      axis.title = element_text(face = "bold", colour = "grey20"),
      axis.text = element_text(colour = "grey30"),
      legend.title = element_text(face = "bold", colour = "grey20"),
      plot.margin = margin(12, 16, 12, 12)
    )
}

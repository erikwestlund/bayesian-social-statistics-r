# Helpers for drawing causal diagrams (DAGs) written in dagitty syntax.
#
# scaffold() sources this file. The DAGs carry their own coordinates, so a
# figure looks the same on every render.

# A DAG as a ggplot: one labelled box per node, one arrow per edge. labels
# maps node names to display text; nodes without a label show their name.
# Latent nodes are drawn with a dashed outline and dashed arrows. Arrows stop
# at a box of half_width by half_height around each node, in data units.
plot_dag <- function(dag, labels = character(), title = NULL, half_width = 0.32, half_height = 0.22) {
  coords <- dagitty::coordinates(dag)
  nodes <- tibble::tibble(name = names(coords$x), x = coords$x, y = -coords$y)
  nodes$label <- ifelse(nodes$name %in% names(labels), labels[nodes$name], nodes$name)
  nodes$latent <- nodes$name %in% dagitty::latents(dag)

  edges <- tibble::as_tibble(dagitty::edges(dag)[c("v", "w")]) |>
    dplyr::left_join(dplyr::select(nodes, v = name, x, y, latent), by = "v") |>
    dplyr::left_join(dplyr::select(nodes, w = name, xend = x, yend = y), by = "w") |>
    # Stop each arrow at the edge of a box around each node, half_width wide
    # and half_height tall, plus a small gap
    dplyr::mutate(
      length = sqrt((xend - x)^2 + (yend - y)^2),
      ux = (xend - x) / length, uy = (yend - y) / length,
      clearance = pmin(half_width / abs(ux), half_height / abs(uy)) + 0.06,
      x = x + clearance * ux, y = y + clearance * uy,
      xend = xend - clearance * ux, yend = yend - clearance * uy
    )

  ggplot2::ggplot() +
    ggplot2::geom_segment(
      ggplot2::aes(x, y, xend = xend, yend = yend, linetype = latent), edges,
      arrow = grid::arrow(length = grid::unit(2.5, "mm"), type = "closed"), linewidth = 0.5
    ) +
    ggplot2::geom_label(
      ggplot2::aes(x, y, label = label, linetype = latent), nodes,
      size = 3.5, label.padding = grid::unit(2.5, "mm")
    ) +
    ggplot2::scale_linetype_manual(values = c(`FALSE` = "solid", `TRUE` = "dashed"), guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(add = 0.6)) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(add = 0.4)) +
    ggplot2::labs(title = title) +
    ggplot2::theme_void()
}

# The adjustment sets for one exposure and outcome, as text: one line per
# set, "(none needed)" for the empty set, "(no set exists)" when the effect
# cannot be identified by adjustment
adjustment_text <- function(dag, exposure, outcome, effect = "total") {
  sets <- dagitty::adjustmentSets(dag, exposure, outcome, effect = effect)
  if (length(sets) == 0) return("(no set exists)")
  vapply(sets, \(set) if (length(set) == 0) "(none needed)" else paste(set, collapse = ", "), "")
}

# scaffold.R
# This file is sourced by framework::scaffold() to set up your project environment

# scaffold() already sets the random seed and the ggplot2 theme from
# settings (scaffold: seed_on_scaffold, seed, set_theme_on_scaffold,
# ggplot_theme). This project: seed 2026, theme_minimal.
# Change them there rather than here, so they are not set twice.

# Add your own setup below.

# Okabe-Ito colors, colorblind-safe, as the default discrete palette
okabe_ito <- unname(palette.colors(palette = "Okabe-Ito"))[c(6, 2, 4, 7, 3, 8, 5)]
options(ggplot2.discrete.colour = okabe_ito, ggplot2.discrete.fill = okabe_ito)

# The first palette colour for single-series lines, curves, areas,
# histograms, and points, so notebooks never name a colour
ggplot2::update_geom_defaults("line", list(colour = okabe_ito[1]))
ggplot2::update_geom_defaults("function", list(colour = okabe_ito[1]))
ggplot2::update_geom_defaults("area", list(fill = okabe_ito[1], colour = NA))
ggplot2::update_geom_defaults("bar", list(fill = okabe_ito[1]))
ggplot2::update_geom_defaults("point", list(colour = okabe_ito[1]))

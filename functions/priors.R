# Priors as objects, and the plots and summaries the priors notebook
# (notebooks/01-simple-regression/01-priors.qmd) needs.
#
# scaffold() sources this file. The Python project's functions/priors.py and
# the Stata project's plot_priors.ado, prior_interval.ado, and prior_share.ado
# do the same.
#
#   wide <- prior_normal(0, 1)
#   narrow <- prior_normal(0, 0.2)
#   plot_priors(c(wide, narrow), x_label = "α", possible = c(-1, 1))
#   interval_text(narrow)            # "-0.39 to 0.39"
#   prior_share(wide, -1, 1)         # 0.68

# A prior: its name; density, distribution, quantile, and random-draw
# functions. label_at
# is where plot_priors() writes the name, on the curve's right flank.
new_prior <- function(name, density, cdf, quantile, random, label_at) {
  structure(
    list(name = name, density = density, cdf = cdf, quantile = quantile, random = random, label_at = label_at),
    class = "prior"
  )
}

prior_normal <- function(mean = 0, sd = 1) {
  new_prior(
    name = sprintf("Normal(%g, %g)", mean, sd),
    density = \(x) stats::dnorm(x, mean, sd),
    cdf = \(x) stats::pnorm(x, mean, sd),
    quantile = \(p) stats::qnorm(p, mean, sd),
    random = \(n) stats::rnorm(n, mean, sd),
    label_at = mean + 1.1 * sd
  )
}

prior_exponential <- function(rate = 1) {
  new_prior(
    name = sprintf("Exponential(%g)", rate),
    density = \(x) stats::dexp(x, rate),
    cdf = \(x) stats::pexp(x, rate),
    quantile = \(p) stats::qexp(p, rate),
    random = \(n) stats::rexp(n, rate),
    label_at = 0.6 / rate
  )
}

# A normal folded at 0: positive values only, for SDs
prior_half_normal <- function(sd = 1) {
  new_prior(
    name = sprintf("Half-normal(0, %g)", sd),
    density = \(x) ifelse(x < 0, 0, 2 * stats::dnorm(x, 0, sd)),
    cdf = \(x) pmax(2 * stats::pnorm(x, 0, sd) - 1, 0),
    quantile = \(p) sd * stats::qnorm((1 + p) / 2),
    random = \(n) abs(stats::rnorm(n, 0, sd)),
    label_at = 1.2 * sd
  )
}

# A Student t folded at 0, with df degrees of freedom and the given scale:
# brms's default for a residual SD is Half-t(3, 0, 2.5)
prior_half_t <- function(df = 3, scale = 2.5) {
  new_prior(
    name = sprintf("Half-t(%g, 0, %g)", df, scale),
    density = \(x) ifelse(x < 0, 0, 2 * stats::dt(x / scale, df) / scale),
    cdf = \(x) pmax(2 * stats::pt(x / scale, df) - 1, 0),
    quantile = \(p) scale * stats::qt((1 + p) / 2, df),
    random = \(n) scale * abs(stats::rt(n, df)),
    label_at = 0.8 * scale
  )
}

# c() of priors keeps each prior whole, giving a list of priors for
# plot_priors(). A plain c() would merge their fields into one list.
c.prior <- function(...) structure(list(...), class = "prior_list")

print.prior <- function(x, ...) {
  cat("<prior>", x$name, "\n")
  invisible(x)
}

# The central interval holding `level` of the prior, as c(lower, upper)
prior_interval <- function(prior, level = 0.95) {
  tail <- (1 - level) / 2
  c(lower = prior$quantile(tail), upper = prior$quantile(1 - tail))
}

# prior_interval() as text for a bullet, such as "-1.96 to 1.96"
interval_text <- function(prior, level = 0.95, digits = 2) {
  bounds <- prior_interval(prior, level)
  paste(sprintf("%.*f", digits, bounds), collapse = " to ")
}

# The share of the prior between lower and upper
prior_share <- function(prior, lower = -Inf, upper = Inf) {
  prior$cdf(upper) - prior$cdf(lower)
}

# Density curves of one prior, or of several combined with c(), on shared
# axes. With two or more, each is labeled on its curve. Colours follow the
# order in c(), from the palette scaffold() sets. limits = c(lower, upper)
# fixes the x axis, so separate plots compare; without it the axis spans the
# priors' central 99.8%. possible = c(lower, upper) shades the parameter's
# possible values.
plot_priors <- function(priors, x_label, limits = NULL, possible = NULL) {
  if (inherits(priors, "prior")) priors <- list(priors)
  names <- vapply(priors, \(p) p$name, character(1))
  if (is.null(limits)) {
    limits <- range(unlist(lapply(priors, \(p) p$quantile(c(0.001, 0.999)))))
  }

  curves <- lapply(priors, \(p) {
    ggplot2::geom_function(
      ggplot2::aes(colour = !!p$name), fun = p$density, n = 501, linewidth = 0.8
    )
  })
  labels <- tibble::tibble(
    prior = names,
    value = vapply(priors, \(p) p$label_at, numeric(1)),
    density = vapply(priors, \(p) p$density(p$label_at), numeric(1))
  )

  # One curve needs no label: the title names it
  text <- if (length(priors) > 1) {
    ggplot2::geom_text(
      ggplot2::aes(value, density, label = prior, colour = prior), labels,
      hjust = 0, vjust = -0.4, size = 3.5
    )
  }

  band <- if (!is.null(possible)) {
    ggplot2::annotate("rect", xmin = possible[1], xmax = possible[2], ymin = -Inf, ymax = Inf, fill = "grey90")
  }

  ggplot2::ggplot() +
    band +
    curves +
    text +
    ggplot2::scale_colour_discrete(limits = names, guide = "none") +
    ggplot2::xlim(limits) +
    ggplot2::expand_limits(y = 0) +
    ggplot2::labs(
      x = x_label, y = "Density", title = list_text(names),
      caption = if (!is.null(possible)) "Grey band: possible values."
    )
}

# Names joined for a title: "A", "A and B", "A, B, and C"
list_text <- function(names) {
  n <- length(names)
  if (n <= 2) return(paste(names, collapse = " and "))
  paste0(paste(names[-n], collapse = ", "), ", and ", names[n])
}

# Mean and SD of the chosen columns, one row per column, rounded
mean_sd_table <- function(data, ..., digits = 2) {
  data |>
    dplyr::select(...) |>
    tidyr::pivot_longer(dplyr::everything(), names_to = "variable") |>
    dplyr::summarise(mean = mean(value), sd = stats::sd(value), .by = variable) |>
    dplyr::mutate(dplyr::across(c(mean, sd), \(x) round(x, digits) + 0))
}

# Prior predictive simulation ------------------------------------------------
#
#   sets <- list(
#     Weaker = prior_set(alpha = prior_normal(0, 1), beta = prior_normal(0, 1), sigma = prior_half_t(3, 2.5)),
#     Stronger = prior_set(alpha = prior_normal(0, 0.2), beta = prior_normal(0, 0.5), sigma = prior_exponential(1))
#   )
#   draws <- draw_priors(sets)
#   plot_prior_lines(draws, ~ alpha + beta * parent_ses_z)
#   simulated <- simulate_outcomes(draws, students, ~ alpha + beta * parent_ses_z)
#   plot_simulated(simulated, parent_ses_z)
#   stats <- simulated_stats(simulated, outcome_sd = sd(y))
#   plot_simulated_stats(stats, reference = c(outcome_sd = 1), log_x = TRUE)

# The priors for one model: one named prior per parameter, any names
prior_set <- function(...) {
  priors <- list(...)
  if (is.null(names(priors)) || any(names(priors) == "")) {
    stop("prior_set(): name every prior, such as prior_set(alpha = prior_normal(0, 1))", call. = FALSE)
  }
  structure(priors, class = "prior_set")
}

# One row per prior set, one column per parameter: the name of its prior.
# sets is a named list of prior_set()s.
prior_set_table <- function(sets) {
  rows <- lapply(sets, \(s) tibble::as_tibble(lapply(s, \(p) p$name)))
  dplyr::bind_rows(rows, .id = "set")
}

# n independent draws of every parameter from each set: one row per set and
# draw, one column per parameter. set is a factor in the order of sets.
draw_priors <- function(sets, n = 4000) {
  draws <- lapply(sets, \(s) {
    tibble::as_tibble(c(list(draw = seq_len(n)), lapply(s, \(p) p$random(n))))
  })
  draws |>
    dplyr::bind_rows(.id = "set") |>
    dplyr::mutate(set = factor(set, names(sets)))
}

# The parameters in a formula that are not columns of draws: the predictors
formula_predictors <- function(formula, draws) {
  setdiff(all.vars(formula), names(draws))
}

# The line each of the first n_lines draws implies for mu, a formula in the
# parameters and one predictor, over x_range of that predictor; other
# predictors are held at 0. One panel per set; band shades the outcome's
# plausible range. Axis labels default to the variable names.
plot_prior_lines <- function(draws, mu, n_lines = 100, x_range = c(-2, 2), band = c(-2, 2),
                             x_label = NULL, y_label = "Expected outcome") {
  predictors <- formula_predictors(mu, draws)
  x <- predictors[1]
  grid <- tibble::tibble(!!x := x_range)
  for (other in predictors[-1]) grid[[other]] <- 0

  draws |>
    dplyr::filter(draw <= n_lines) |>
    tidyr::expand_grid(grid) |>
    dplyr::mutate(mu = rlang::eval_tidy(rlang::f_rhs(mu), dplyr::pick(dplyr::everything()))) |>
    ggplot2::ggplot(ggplot2::aes(.data[[x]], mu, group = draw)) +
    ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = band[1], ymax = band[2], fill = "grey90") +
    ggplot2::geom_line(alpha = 0.3, linewidth = 0.4) +
    ggplot2::facet_wrap(~set) +
    ggplot2::labs(
      x = x_label %||% x, y = y_label,
      title = sprintf("Implied lines, %d draws from each prior set", n_lines),
      caption = sprintf("Grey band: %g to %g on the outcome's scale.", band[1], band[2])
    )
}

# Simulated outcomes: for each draw (the first n_draws, or all), one outcome
# per row of data. mu is a formula in the parameters and data columns.
# family: "normal" (needs a sigma parameter), "bernoulli" (mu on the log-odds
# scale), or "poisson" (mu on the log scale). Adds row, mu, and y.
simulate_outcomes <- function(draws, data, mu, family = c("normal", "bernoulli", "poisson"), n_draws = NULL) {
  family <- match.arg(family)
  if (!is.null(n_draws)) draws <- dplyr::filter(draws, draw <= n_draws)
  simulated <- draws |>
    tidyr::expand_grid(dplyr::mutate(data, row = dplyr::row_number())) |>
    dplyr::mutate(mu = rlang::eval_tidy(rlang::f_rhs(mu), dplyr::pick(dplyr::everything())))
  n <- nrow(simulated)
  simulated$y <- switch(family,
    normal = stats::rnorm(n, simulated$mu, simulated$sigma),
    bernoulli = stats::rbinom(n, 1, stats::plogis(simulated$mu)),
    poisson = stats::rpois(n, exp(simulated$mu))
  )
  simulated
}

# simulate_outcomes() as small scatter plots of y against x, for the first
# n_draws draws of each set, ncol to a row, the sets one after another, on
# shared axes so the sets compare. Dashed lines mark reference values of the
# outcome.
plot_simulated <- function(simulated, x, n_draws = 16, ncol = 8, reference = c(-2, 2),
                           x_label = NULL, y_label = "Simulated outcome") {
  x_name <- rlang::as_name(rlang::enquo(x))
  shown <- dplyr::filter(simulated, draw <= n_draws)
  shown |>
    dplyr::arrange(set, draw) |>
    dplyr::mutate(panel = forcats::fct_inorder(paste(set, draw))) |>
    ggplot2::ggplot(ggplot2::aes({{ x }}, y)) +
    ggplot2::geom_hline(yintercept = reference, linetype = "dashed", colour = "#D55E00", linewidth = 0.4) +
    ggplot2::geom_point(size = 0.2, alpha = 0.5) +
    ggplot2::facet_wrap(~panel, ncol = ncol) +
    ggplot2::scale_x_continuous(breaks = c(-2, 0, 2)) +
    ggplot2::labs(
      x = x_label %||% x_name, y = y_label,
      title = sprintf("Simulated data sets, %d draws from each prior set, %d rows each",
                      n_draws, dplyr::n_distinct(shown$row)),
      caption = sprintf("Red dashed lines: %s on the outcome's scale.", paste(reference, collapse = " and "))
    ) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 6),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing = ggplot2::unit(3, "pt"),
      strip.text = ggplot2::element_text(size = 7)
    )
}

# Statistics of each simulated data set, named as in dplyr::summarise(), such
# as outcome_sd = sd(y) or share_one = mean(y): one row per set and draw
simulated_stats <- function(simulated, ...) {
  dplyr::summarise(simulated, ..., .by = c(set, draw))
}

# simulated_stats() as histograms: one panel per set and statistic. reference
# is a named vector of values to mark, such as c(outcome_sd = 1) for the
# observed outcome SD. log_x = TRUE puts the x axis on a log scale, for
# statistics with long right tails.
plot_simulated_stats <- function(stats, reference = NULL, log_x = FALSE, bins = 50) {
  long <- tidyr::pivot_longer(stats, -c(set, draw), names_to = "statistic")
  lines <- if (!is.null(reference)) {
    tibble::tibble(statistic = names(reference), value = unname(reference))
  }
  plot <- ggplot2::ggplot(long, ggplot2::aes(value)) +
    ggplot2::geom_histogram(bins = bins) +
    ggplot2::facet_grid(set ~ statistic, scales = "free_x") +
    ggplot2::labs(
      x = NULL, y = "Simulated data sets",
      title = sprintf("Statistics of %s simulated data sets per prior set",
                      format(dplyr::n_distinct(stats$draw), big.mark = ",")),
      caption = if (!is.null(reference)) {
        sprintf("Red dashed %s: %s in the observed data (%s).",
                if (length(reference) > 1) "lines" else "line",
                if (length(reference) > 1) "values" else "the value",
                paste(names(reference), "=", format(reference), collapse = ", "))
      }
    )
  if (!is.null(lines)) {
    plot <- plot + ggplot2::geom_vline(
      ggplot2::aes(xintercept = value), lines, linetype = "dashed", colour = "#D55E00", linewidth = 0.6
    )
  }
  if (log_x) plot <- plot + ggplot2::scale_x_log10(labels = scales::label_number(drop0trailing = TRUE))
  plot
}

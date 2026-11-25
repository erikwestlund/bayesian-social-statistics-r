# Helpers for the Bayesian notebooks: the analysis sample, Stan models, and fits.
#
# scaffold() sources this file. The Stan programs are in stan/, shared with
# the Python project. The functions match functions/bayes.py there.

# The predictors, centered: base-year math minus 50, the T-score mean, and SES
# as it is (a standardized composite with mean near 0)
PREDICTORS <- c("w1_math_c", "w1_ses")
OUTCOME <- "w2_math"

# Weakly informative priors on the T-score scale. The intercept is the expected
# follow-up score for a student at the mean on both predictors, so a prior
# centered at 50 with SD 10 allows anything from 30 to 70. A slope of 2.5 per
# point of base-year math or per SD of SES would be implausibly large.
WEAK <- list(
  alpha_mean = 50,
  alpha_sd = 10,
  beta_mean = c(0, 0),
  beta_sd = c(2.5, 2.5),
  sigma_rate = 0.1
)

# Students with both math scores and SES, with base-year math centered at 50
analysis_sample <- function(clean) {
  clean |>
    tidyr::drop_na(w1_math, w2_math, w1_ses) |>
    dplyr::mutate(w1_math_c = w1_math - 50)
}

# Compile stan/<name>.stan, or reuse the executable when it is current
bayes_model <- function(name) {
  cmdstanr::cmdstan_model(file.path("stan", paste0(name, ".stan")))
}

# The data block for stan/regression.stan. priors = NULL gives flat priors.
stan_data <- function(data, priors = NULL, prior_only = FALSE, predict = FALSE) {
  flat <- is.null(priors)
  if (flat) {
    priors <- WEAK
  }
  list(
    N = nrow(data),
    K = length(PREDICTORS),
    X = as.matrix(data[PREDICTORS]),
    y = data[[OUTCOME]],
    prior = as.integer(!flat),
    alpha_mean = priors$alpha_mean,
    alpha_sd = priors$alpha_sd,
    beta_mean = priors$beta_mean,
    beta_sd = priors$beta_sd,
    sigma_rate = priors$sigma_rate,
    prior_only = as.integer(prior_only),
    predict = as.integer(predict)
  )
}

# Four chains of 1,000 warmup and 1,000 sampling iterations, in parallel and
# without progress output. CmdStan also reports each rejected proposal during
# warmup, and cmdstanr warns about divergences and tree depth after sampling;
# the notebooks report the diagnostics that matter instead. Arguments in ...
# go to $sample() and override these.
bayes_sample <- function(model, data, seed = 123, ...) {
  options <- utils::modifyList(
    list(
      chains = 4,
      parallel_chains = 4,
      iter_warmup = 1000,
      iter_sampling = 1000,
      seed = seed,
      refresh = 0,
      show_messages = FALSE,
      show_exceptions = FALSE,
      diagnostics = NULL
    ),
    list(...)
  )
  do.call(model$sample, c(list(data = data), options))
}

# Fake students from the regression model, with predictors that look like HSLS:09.
#
# Base-year math is normal with mean 51.7 and SD 10. SES is normal with mean
# 0.08 and SD 0.8 and correlates 0.43 with base-year math. These round the
# values in the HSLS:09 analysis sample. The follow-up score comes from the
# model with the given parameters. The draws use R's random number generator,
# so set.seed() makes them reproducible.
simulate <- function(n, alpha, beta, sigma) {
  mean <- c(1.7, 0.08)
  sd <- c(10, 0.8)
  correlation <- matrix(c(1, 0.43, 0.43, 1), 2)
  covariance <- correlation * outer(sd, sd)
  x <- matrix(stats::rnorm(n * 2), n) %*% chol(covariance) + rep(mean, each = n)
  tibble::tibble(
    w1_math_c = x[, 1],
    w1_ses = x[, 2],
    w1_math = x[, 1] + 50,
    w2_math = alpha + drop(x %*% beta) + stats::rnorm(n, 0, sigma)
  )
}

# Posterior draws as a tibble, one row per draw, with chain and draw columns.
# The columns are alpha, beta[1], beta[2], sigma unless names are given.
draws <- function(fit, names = c("alpha", "beta[1]", "beta[2]", "sigma")) {
  frame <- posterior::as_draws_df(fit$draws(variables = names))
  tibble::as_tibble(c(
    list(chain = frame$.chain, draw = frame$.draw),
    as.list(as.data.frame(frame)[names])
  ))
}

# The central (equal-tailed) interval holding the given share of the values
interval <- function(values, level = 0.95) {
  tail <- (1 - level) / 2
  unname(stats::quantile(values, c(tail, 1 - tail)))
}

# Draw ggplots in a grid on one page, filled by row, with an optional title
# above them all. It uses the grid package that ships with R.
arrange_plots <- function(plots, ncol, title = NULL) {
  nrow <- ceiling(length(plots) / ncol)
  top <- if (is.null(title)) 0 else 1
  heights <- grid::unit(rep(1, nrow), "null")
  if (top == 1) {
    heights <- grid::unit.c(grid::unit(2, "lines"), heights)
  }
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(nrow + top, ncol, heights = heights)))
  if (top == 1) {
    grid::grid.text(title, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = seq_len(ncol)), gp = grid::gpar(fontsize = 13))
  }
  for (i in seq_along(plots)) {
    position <- grid::viewport(layout.pos.row = top + (i - 1) %/% ncol + 1, layout.pos.col = (i - 1) %% ncol + 1)
    print(plots[[i]], vp = position)
  }
  invisible(NULL)
}

# Helpers for fitting one regression by OLS and with brms, and comparing them.
#
# scaffold() sources this file. The brms parameter names follow brms:
# b_Intercept and b_<predictor> for coefficients, sigma for the residual SD.
# Formulas for brm() use `0 + Intercept`, so the intercept is an ordinary
# coefficient with the same prior class as the slopes.

# Subtract the mean and divide by the SD
standardize <- function(x) (x - mean(x)) / sd(x)

# The mobility analysis file: ELS:2002 students with both SES measures, with
# family SES (parent_ses_z) and adult SES (adult_ses_z) standardized.
# els_clean is built by scripts/els/02_clean.R.
read_mobility <- function() {
  els <- data_read(
    "inputs.final.els_clean",
    col_select = c("student_id", "w1_ses", "w4_ses"),
    col_types = readr::cols(student_id = "c", .default = "d")
  )
  els |>
    tidyr::drop_na(w1_ses, w4_ses) |>
    dplyr::mutate(parent_ses_z = standardize(w1_ses), adult_ses_z = standardize(w4_ses))
}

# Fit a brms model with four chains of 1,000 warmup and 1,000 sampling
# iterations, without progress output. prior = NULL keeps the brms defaults.
fit_brms <- function(formula, data, prior = NULL, seed = 2026) {
  brms::brm(formula, data = data, prior = prior, backend = "cmdstanr",
            chains = 4, cores = 4, seed = seed, refresh = 0, silent = 2)
}

# Refit a brms model to new data without recompiling it
refit_brms <- function(fit, data, seed = 2026) {
  stats::update(fit, newdata = data, seed = seed, refresh = 0, silent = 2)
}

# OLS estimates and 95% confidence intervals, with the residual SD last.
# labels names the rows in the order of coef(fit), then the residual SD.
ols_table <- function(fit, labels) {
  ci <- stats::confint(fit)
  data.frame(
    `OLS estimate` = c(stats::coef(fit), stats::sigma(fit)),
    `OLS 2.5%` = c(ci[, 1], NA),
    `OLS 97.5%` = c(ci[, 2], NA),
    row.names = labels,
    check.names = FALSE
  )
}

# Posterior mean and central 95% interval of each parameter. parameters is a
# named vector: brms parameter names, with the row labels as names.
posterior_table <- function(fit, parameters, label = "Posterior") {
  fit_draws <- posterior::as_draws_df(fit)
  rows <- lapply(parameters, \(name) {
    values <- fit_draws[[name]]
    c(mean(values), interval(values))
  })
  table <- as.data.frame(do.call(rbind, rows), row.names = names(parameters))
  names(table) <- paste(label, c("mean", "2.5%", "97.5%"))
  table
}

# Priors for a regression with one slope: Normal(center, sd) on the slope,
# Normal(0, intercept_sd) on the intercept, Exponential(sigma_rate) on the
# residual SD
slope_prior <- function(term, center, sd, intercept_sd = 1, sigma_rate = 1) {
  c(
    brms::set_prior(sprintf("normal(0, %f)", intercept_sd), class = "b", coef = "Intercept"),
    brms::set_prior(sprintf("normal(%f, %f)", center, sd), class = "b", coef = term),
    brms::set_prior(sprintf("exponential(%f)", sigma_rate), class = "sigma")
  )
}

# How many observations a normal prior on a slope is worth: the sample size
# whose standard error equals the prior SD. One observation's information
# about the slope is about var(x) / sigma^2.
observations_worth <- function(prior_sd, sigma, x) {
  (sigma / prior_sd)^2 / stats::var(x)
}

# One slope's estimate and 95% interval, from OLS or from posterior draws
ols_slope <- function(formula, data, term) {
  fit <- stats::lm(formula, data)
  ci <- stats::confint(fit)[term, ]
  tibble::tibble(Estimate = stats::coef(fit)[[term]], Low = ci[[1]], High = ci[[2]])
}
posterior_slope <- function(fit, term) {
  draws <- posterior::as_draws_df(fit)[[paste0("b_", term)]]
  bounds <- interval(draws)
  tibble::tibble(Estimate = mean(draws), Low = bounds[1], High = bounds[2])
}

# Fit OLS and each prior to the first n rows of data, for each n in sizes.
# priors is a named list of brms priors (NULL for flat). Each prior's model is
# compiled once and refit with refit_brms(). Returns one row per fit and size.
prior_sweep <- function(data, ols_formula, brms_formula, term, priors, sizes) {
  rows <- lapply(sizes, \(n) {
    dplyr::mutate(ols_slope(ols_formula, data[seq_len(n), ], term), Fit = "OLS", n = n)
  })
  for (name in names(priors)) {
    model <- fit_brms(brms_formula, data[seq_len(sizes[1]), ], priors[[name]])
    for (n in sizes) {
      model <- refit_brms(model, data[seq_len(n), ])
      rows[[length(rows) + 1]] <- dplyr::mutate(posterior_slope(model, term), Fit = name, n = n)
    }
  }
  dplyr::bind_rows(rows) |>
    dplyr::mutate(Fit = factor(Fit, c("OLS", names(priors))))
}

# Unnormalized posterior over intercept and slope on a grid, with the
# residual SD fixed: the log prior plus every observation's log normal
# density, rescaled so the largest cell is 1. grid has columns intercept and
# slope.
grid_posterior <- function(grid, y, x, sigma, slope_center = 0, slope_sd = 0.5, intercept_sd = 1) {
  log_post <- mapply(\(a, b) {
    sum(stats::dnorm(y, a + b * x, sigma, log = TRUE)) +
      stats::dnorm(a, 0, intercept_sd, log = TRUE) +
      stats::dnorm(b, slope_center, slope_sd, log = TRUE)
  }, grid$intercept, grid$slope)
  dplyr::mutate(grid, density = exp(log_post - max(log_post)))
}

# OLS and posterior side by side, paired by quantity: estimate next to
# posterior mean, then each interval bound. parameters is as in
# posterior_table(), in the order of coef(ols), then sigma.
ols_posterior_table <- function(ols, fit, parameters) {
  ols_part <- ols_table(ols, names(parameters))
  post_part <- posterior_table(fit, parameters)
  table <- cbind(ols_part, post_part)[c(1, 4, 2, 5, 3, 6)]
  names(table) <- c("OLS estimate", "Posterior mean", "OLS 2.5%", "Posterior 2.5%", "OLS 97.5%", "Posterior 97.5%")
  table
}

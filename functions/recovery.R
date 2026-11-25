# Helpers for fitting a model to simulated data and checking that it recovers
# the values the data were simulated from.
#
# scaffold() sources this file. It uses fit_brms() and refit_brms() from
# regression.R and interval() from bayes.R.

# Outcomes simulated from a one-predictor normal regression with known
# intercept, slope, and residual SD, at the given predictor values
simulate_regression <- function(x, intercept, slope, sigma) {
  stats::rnorm(length(x), intercept + slope * x, sigma)
}

# Fit one model to the first n rows of data, for each n in sizes, and
# summarise each parameter: posterior mean and central 95% interval.
# parameters is a named vector of brms parameter names, with display labels as
# names. The model is compiled once and refit with refit_brms(). Returns one
# row per size and parameter.
recovery_sweep <- function(data, formula, prior, sizes, parameters) {
  model <- fit_brms(formula, data[seq_len(sizes[1]), ], prior)
  rows <- lapply(sizes, \(n) {
    model <- refit_brms(model, data[seq_len(n), ])
    draws <- posterior::as_draws_df(model)
    dplyr::bind_rows(lapply(names(parameters), \(label) {
      values <- draws[[parameters[[label]]]]
      bounds <- interval(values)
      tibble::tibble(n = n, parameter = label, mean = mean(values), low = bounds[1], high = bounds[2])
    }))
  })
  dplyr::bind_rows(rows) |>
    dplyr::mutate(parameter = factor(parameter, names(parameters)))
}

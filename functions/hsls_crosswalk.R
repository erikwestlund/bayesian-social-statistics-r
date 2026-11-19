# Helpers for reading the HSLS:09 crosswalk (inputs/public/raw/hsls_crosswalk.csv)

# "-9;-8" as c(-9, -8). An empty cell gives no codes.
crosswalk_codes <- function(text) {
  if (text == "") {
    return(numeric())
  }
  as.numeric(strsplit(text, ";", fixed = TRUE)[[1]])
}

# Recode x with pairs such as "1=0;2=1". Values not listed stay as they are.
crosswalk_recode <- function(x, text) {
  if (text == "") {
    return(x)
  }
  pairs <- strsplit(strsplit(text, ";", fixed = TRUE)[[1]], "=", fixed = TRUE)
  old <- as.numeric(vapply(pairs, `[`, "", 1))
  new <- as.numeric(vapply(pairs, `[`, "", 2))
  matched <- match(x, old)
  ifelse(is.na(matched), x, new[matched])
}

# "1=City;2=Suburb" as c("1" = "City", "2" = "Suburb"). Look a value up with
# its number as text, such as labels[as.character(2)]. An empty cell gives no
# labels.
crosswalk_labels <- function(text) {
  if (text == "") {
    return(character())
  }
  pairs <- strsplit(text, ";", fixed = TRUE)[[1]]
  split <- regexpr("=", pairs, fixed = TRUE)
  values <- as.numeric(substr(pairs, 1, split - 1))
  stats::setNames(substring(pairs, split + 1), as.character(values))
}

# Why each value in the clean file is missing, one column per variable.
#
# Each cell is one of:
# - "Observed": the clean value is present
# - "Nonresponse": the raw value is a nonresponse code or blank
# - "Logical skip": the raw value is a logical-skip code
# - "Outside the flag": the raw value is an answer, but the crosswalk's
#   within flag is not 1 for this student
#
# A flag built from a logical skip (derive = "applies") turns the skip into 0,
# so its skips count as observed. raw and clean must hold the same students in
# the same order.
missing_reasons <- function(raw, clean, crosswalk) {
  reasons <- tibble::tibble(.rows = nrow(clean))
  for (i in seq_len(nrow(crosswalk))) {
    row <- crosswalk[i, ]
    source <- raw[[row$nces]]
    observed <- !is.na(clean[[row$name]])
    nonresponse <- source %in% crosswalk_codes(row$missing) | is.na(source)
    skipped <- source %in% crosswalk_codes(row$skip)
    reasons[[row$name]] <- dplyr::case_when(
      observed ~ "Observed",
      nonresponse ~ "Nonresponse",
      skipped ~ "Logical skip",
      .default = "Outside the flag"
    )
  }
  reasons
}

# Mean and SD of x with weights, over the cases where both are present and the
# weight is above 0. The SD is the population SD: it divides by the sum of the
# weights.
weighted_mean_sd <- function(x, weight) {
  keep <- !is.na(x) & !is.na(weight) & weight > 0
  x <- x[keep]
  weight <- weight[keep]
  mean <- sum(weight * x) / sum(weight)
  sd <- sqrt(sum(weight * (x - mean)^2) / sum(weight))
  c(mean = mean, sd = sd)
}

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

# Build the analysis file from the HSLS:09 student file.
#
# Run from the project root:  Rscript scripts/hsls/02_clean.R
#
# inputs/public/raw/hsls_crosswalk.csv drives every step: which NCES variables
# to keep, missing-value codes, recodes, and the new names. The Python and
# Stata projects keep the same crosswalk, so all three build the same file.
#
# NCES marks missing values with negative reserve codes, and the crosswalk
# splits them in two (see docs/missing-data.md):
#
# - missing: nonresponse (-9, -8, -4, ...). The question applied but went
#   unanswered. Analyses impute these or model them.
# - skip: logical skips (-7, -6). The question did not apply, such as parent 2
#   education in a one-parent family. Analyses usually drop these cases.
#
# Both become missing values, so a flag keeps the difference. A row with
# derive = "applies" builds a 0/1 flag from its source: 0 for a logical skip,
# 1 for an answer, missing for nonresponse. A row with fill = <name>=<value>
# takes that value wherever it is still missing and the named variable is
# observed. A row with within = <flag> is missing wherever that flag is not 1.
#
# Only the listed codes become missing. Several variables, such as the SES
# composite, have real negative values, so "negative means missing" would drop
# real data.

library(framework)
scaffold()

# Read every cell as text and keep empty cells as "", not NA
crosswalk <- data_read(
  "inputs.public.raw.hsls_crosswalk",
  col_types = readr::cols(.default = "c"),
  na = character()
)

raw <- data_read(
  "inputs.private.raw.hsls_student",
  col_select = unique(crosswalk$nces),
  col_types = readr::cols(STU_ID = "c", .default = "d")
)

clean <- tibble::tibble(.rows = nrow(raw))
for (i in seq_len(nrow(crosswalk))) {
  row <- crosswalk[i, ]
  source <- raw[[row$nces]]
  # A blank cell is missing too, so a flag never reads it as an answer
  missing <- source %in% crosswalk_codes(row$missing) | is.na(source)
  skipped <- source %in% crosswalk_codes(row$skip)

  if (row$derive == "applies") {
    column <- ifelse(missing, NA_real_, as.numeric(!skipped))
  } else {
    column <- source
    column[missing | skipped] <- NA
    column <- crosswalk_recode(column, row$recode)
  }

  if (row$fill != "") {
    fill <- strsplit(row$fill, "=", fixed = TRUE)[[1]]
    column[is.na(column) & !is.na(clean[[fill[1]]])] <- as.numeric(fill[2])
  }

  if (row$within != "") {
    column[is.na(clean[[row$within]]) | clean[[row$within]] != 1] <- NA
  }

  clean[[row$name]] <- column
}

data_save(clean, "inputs/private/final/hsls_clean.csv")
message(format(nrow(clean), big.mark = ","), " students, ", ncol(clean), " variables")

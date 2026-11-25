# Build the analysis file from the ELS:2002 student file.
#
# Run from the project root:  Rscript scripts/els/02_clean.R
#
# inputs/public/raw/els_crosswalk.csv drives every step: which NCES variables
# to keep, missing-value codes, recodes, and the new names. The names follow
# the HSLS:09 crosswalk, so code written for one study reads the other. The
# crosswalk extends the one in the els-2002-r project with the 2012 (third
# follow-up) variables, named w4_.
#
# This file is the cleaned ELS:2002 data for the whole series. lab.phpstats.org
# loads it; nothing flows the other way.

library(framework)
scaffold()

# Read every cell as text and keep empty cells as "", not NA
crosswalk <- data_read(
  "inputs.public.raw.els_crosswalk",
  col_types = readr::cols(.default = "c"),
  na = character()
)

raw <- data_read(
  "inputs.private.raw.els_student",
  col_select = unique(c(crosswalk$nces, "SCH_ID")),
  col_types = readr::cols(STU_ID = "c", .default = "d")
)

clean <- tibble::tibble(.rows = nrow(raw))
for (i in seq_len(nrow(crosswalk))) {
  row <- crosswalk[i, ]
  source <- raw[[row$nces]]
  # A blank cell is missing too, so a flag never reads it as an answer
  missing <- source %in% crosswalk_codes(row$missing) | is.na(source)
  skipped <- source %in% crosswalk_codes(row$skip)

  column <- source
  column[missing | skipped] <- NA
  column <- crosswalk_recode(column, row$recode)
  if (row$fill != "") {
    rule <- strsplit(row$fill, "=", fixed = TRUE)[[1]]
    column[is.na(column) & !is.na(clean[[rule[1]]])] <- as.numeric(rule[2])
  }
  allowed <- names(crosswalk_labels(row$labels))
  if (length(allowed) && any(!is.na(column) & !column %in% allowed)) {
    stop("Unlabelled value in ", row$name)
  }
  clean[[row$name]] <- column
}

# Every reserve code the crosswalk does not list would pass through as a
# value. These variables have no real negative values, so any left is a code
# the crosswalk missed.
nonnegative <- setdiff(crosswalk$name, c("student_id", "w1_ses", "w1_ses_duncan", "w4_ses"))
leftover <- vapply(clean[nonnegative], \(x) sum(x < 0, na.rm = TRUE), 0L)
if (any(leftover > 0)) {
  stop("Unlisted negative codes in: ", paste(names(leftover)[leftover > 0], collapse = ", "))
}

stopifnot(all(raw$SCH_ID == -5), !anyNA(clean$student_id), !anyDuplicated(clean$student_id),
          !anyDuplicated(crosswalk$name), !anyNA(clean$stratum), n_distinct(clean$stratum) == 361,
          all(clean$psu %in% 1:3))
# PSU occupies one digit in the NCES design key (2006-344, appendix G).
clean$school_id <- 10 * clean$stratum + clean$psu
sizes <- table(clean$school_id)
message(length(sizes), " base-year school clusters, median size ", median(sizes))

components <- c("w1_income_imputed", "w1_mother_edu_imputed", "w1_father_edu_imputed",
                "w1_mother_occ_imputed", "w1_father_occ_imputed")
clean$w1_ses_imputed <- ifelse(is.na(clean$w1_ses), NA_integer_,
                               as.integer(rowSums(clean[components]) > 0))
stopifnot(identical(is.na(clean$w2_math), clean$w2_test_status %in% c(0, 4)),
          all(clean$w2_math_imputed == (clean$w2_test_status %in% c(2, 3)), na.rm = TRUE),
          identical(is.na(clean$w1_ses_imputed), is.na(clean$w1_ses)))

# The separate NCES replicate file uses the same student key as the CSV.
by_names <- paste0("BYSTU", 1:200)
f1_names <- paste0("F1PNL", 1:200)
replicates <- haven::read_sav(
  project_path("inputs/private/raw/els/els_02_12_byf3stubrr_v1_0.sav"),
  col_select = all_of(c("STU_ID", by_names, f1_names))
)
key <- as.character(replicates$STU_ID)
stopifnot(!anyNA(key), !anyDuplicated(key), setequal(clean$student_id, key))
weights <- replicates[match(clean$student_id, key), c(by_names, f1_names)]
stopifnot(all(vapply(weights, function(x) all(is.finite(x) & x >= 0), logical(1))))
names(weights) <- c(paste0("w1_weight_rep", 1:200), paste0("w2_weight_panel_rep", 1:200))
clean <- bind_cols(clean, weights)

data_save(clean, "inputs/private/final/els_clean.csv")
message(format(nrow(clean), big.mark = ","), " students, ", ncol(clean), " variables")

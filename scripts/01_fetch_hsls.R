# Download the HSLS:09 public-use file from NCES and extract it.
#
# Run from the project root:  Rscript scripts/01_fetch_hsls.R
#
# By downloading, you accept the NCES data usage agreement: use the data for
# statistical purposes only, make no attempt to identify anyone, and do not
# link it to individually identifiable data.

library(framework)
scaffold()

url <- "https://nces.ed.gov/EDAT/Data/Zip/HSLS_2016_v1_0_CSV_Datasets.zip"
sha256 <- "a4de968eefbac25a2b6f7337931f8c8051ddfcd2fd82920041a3c8abbebbd4aa"

folder <- project_path("inputs/private/raw/hsls")
archive <- file.path(folder, "HSLS_2016_v1_0_CSV_Datasets.zip")
dir.create(folder, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(archive)) {
  message("Downloading ", url, " (about 270 MB)")
  # R's default 60-second timeout is too short for 270 MB
  options(timeout = max(3600, getOption("timeout")))
  download.file(url, archive, mode = "wb")
}

if (digest::digest(file = archive, algo = "sha256") != sha256) {
  stop(archive, " does not match the expected SHA-256. Delete it and run again.")
}

members <- unzip(archive, list = TRUE)$Name
missing_members <- members[!file.exists(file.path(folder, members))]
if (length(missing_members) > 0) {
  unzip(archive, files = missing_members, exdir = folder)
}

message("HSLS:09 files are in ", folder)

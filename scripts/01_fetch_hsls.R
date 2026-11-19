# Download the HSLS:09 public-use file and its documentation from NCES.
#
# Run from the project root:  Rscript scripts/01_fetch_hsls.R
#
# By downloading, you accept the NCES data usage agreement: use the data for
# statistical purposes only, make no attempt to identify anyone, and do not
# link it to individually identifiable data.
#
# The data go to inputs/private/raw/hsls and stay out of git. The NCES
# documentation goes to inputs/public/raw/hsls_docs, which git also ignores
# because the PDFs are large. Every download is checked against its SHA-256
# before it takes its final name, and every file extracted from the zip is
# checked against the zip's own length, so an interrupted run leaves nothing
# behind that a later run would trust.

library(framework)
scaffold()

data_folder <- "inputs/private/raw/hsls"
docs_folder <- "inputs/public/raw/hsls_docs"

downloads <- tibble::tribble(
  ~folder, ~url, ~sha256,
  data_folder,
  "https://nces.ed.gov/EDAT/Data/Zip/HSLS_2016_v1_0_CSV_Datasets.zip",
  "a4de968eefbac25a2b6f7337931f8c8051ddfcd2fd82920041a3c8abbebbd4aa",
  docs_folder,
  "https://nces.ed.gov/surveys/hsls09/pdf/2011328_1.pdf",
  "888a17c972d8d38350f6084be06fce251666cca9ecba22f2af1359400e8faca9",
  docs_folder,
  "https://nces.ed.gov/surveys/hsls09/pdf/2011328_2.pdf",
  "9ad7520cca392a38d392ec29c486c4f1e16f30e8e122bbe02b8c64bf9775cf22",
  docs_folder,
  "https://nces.ed.gov/pubs2014/2014361_AppendixI.pdf",
  "7d5588edb241faa3dc3b15d83bee9de3196bb6b5fc7f4ef6e686560f5702c286",
  docs_folder,
  "https://nces.ed.gov/pubs2018/2018140.pdf",
  "d5a9bef3822b76a964bf5b1ddd095bfbbbea4eb87330a88eb1b050951f6e837b"
)

# R's default 60-second timeout is too short for the 270 MB data file
options(timeout = max(3600, getOption("timeout")))

sha256_of <- function(path) digest::digest(file = path, algo = "sha256")

# Download url into folder unless a checked copy is there
fetch <- function(folder, url, sha256) {
  folder <- project_path(folder)
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  target <- file.path(folder, basename(url))
  if (file.exists(target)) {
    if (sha256_of(target) != sha256) {
      stop(target, " does not match the expected SHA-256. Delete it and run again.")
    }
    return(target)
  }
  partial <- paste0(target, ".part")
  message("Downloading ", url)
  download.file(url, partial, mode = "wb")
  if (sha256_of(partial) != sha256) {
    unlink(partial)
    stop("The download of ", url, " does not match the expected SHA-256. Run again.")
  }
  file.rename(partial, target)
  target
}

files <- purrr::pmap_chr(downloads, fetch)

# Extract each zip member unless a complete copy is there
archive <- files[1]
members <- unzip(archive, list = TRUE)
targets <- file.path(dirname(archive), members$Name)
complete <- file.exists(targets) & file.size(targets) == members$Length
for (i in which(!complete)) {
  message("Extracting ", members$Name[i])
  scratch <- tempfile(tmpdir = dirname(archive))
  unzip(archive, files = members$Name[i], exdir = scratch)
  file.rename(file.path(scratch, members$Name[i]), targets[i])
  unlink(scratch, recursive = TRUE)
}

message(
  "HSLS:09 files are in ", project_path(data_folder),
  ", documentation in ", project_path(docs_folder)
)

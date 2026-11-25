# Download and extract the NCES files that shared/data_locations.csv lists,
# for one data set, such as fetch_data("els"), or for all of them.
#
# The file has one row per file: dataset, path (where it goes, relative to
# the project root), url (where to download it) or from (the zip, another
# row's path, to extract it from), and its sha256. The crc and bytes columns
# are for Stata, which has no SHA-256.
#
# A file already in place is checked, not fetched again. A download or an
# extracted file takes its final name only after its SHA-256 matches, so an
# interrupted run leaves nothing behind that a later run would trust.
fetch_data <- function(dataset = NULL, locations = "shared/data_locations.csv") {
  rows <- readr::read_csv(project_path(locations), col_types = readr::cols(.default = "c"), na = character())
  if (!is.null(dataset)) {
    unknown <- setdiff(dataset, rows$dataset)
    if (length(unknown)) stop(locations, " lists no data set ", paste(unknown, collapse = ", "), call. = FALSE)
    rows <- rows[rows$dataset %in% dataset, ]
  }
  sha256_of <- function(path) digest::digest(file = path, algo = "sha256")
  checked <- function(path, sha256) file.exists(path) && sha256_of(path) == sha256

  # Large NCES files take longer than R's default 60-second timeout
  options(timeout = max(3600, getOption("timeout")))

  for (i in seq_len(nrow(rows))) {
    row <- rows[i, ]
    target <- project_path(row$path)
    if (checked(target, row$sha256)) next
    if (file.exists(target) && row$url != "") {
      stop(row$path, " does not match the expected SHA-256. Delete it and run again.", call. = FALSE)
    }
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    partial <- paste0(target, ".part")
    if (row$url != "") {
      message("Downloading ", row$url)
      utils::download.file(row$url, partial, mode = "wb", quiet = TRUE)
    } else {
      message("Extracting ", basename(row$path), " from ", basename(row$from))
      scratch <- tempfile(tmpdir = dirname(target))
      utils::unzip(project_path(row$from), files = basename(row$path), exdir = scratch)
      file.rename(file.path(scratch, basename(row$path)), partial)
      unlink(scratch, recursive = TRUE)
    }
    if (!checked(partial, row$sha256)) {
      unlink(partial)
      stop(row$path, " does not match the expected SHA-256. Run again.", call. = FALSE)
    }
    file.rename(partial, target)
  }
  invisible(rows$path)
}

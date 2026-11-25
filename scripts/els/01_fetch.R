# Download the ELS:2002 public-use file and its documentation from NCES.
#
# Run from the project root:  Rscript scripts/els/01_fetch.R
#
# By downloading, you accept the NCES data usage agreement: use the data for
# statistical purposes only, make no attempt to identify anyone, and do not
# link it to individually identifiable data.
#
# The data go to inputs/private/raw/els and stay out of git. The NCES
# documentation goes to inputs/public/raw/els_docs, which git also ignores
# because the PDFs are large. Every download is checked against its SHA-256
# before it takes its final name, and every file extracted from the zip is
# checked against the zip's own length, so an interrupted run leaves nothing
# behind that a later run would trust.

library(framework)
scaffold()

data_folder <- "inputs/private/raw/els"
docs_folder <- "inputs/public/raw/els_docs"

downloads <- tibble::tribble(
  ~folder, ~url, ~sha256,
  data_folder,
  "https://nces.ed.gov/EDAT/Data/Zip/ELS_2002-12_v1_0_CSV_Datasets.zip",
  "b255f2c1821618cd7039f5ab7c4e6ed92caa536598cffc383b4f012deba411fb",
  data_folder,
  "https://nces.ed.gov/EDAT/Data/Zip/ELS_2002-12_PETS_v1_0_Student_BRR_SPSS_Datasets.zip",
  "52657e8ba182fb1c359d924cd7b552adddb749778846bff60eff000b57f690f7",
  docs_folder,
  "https://nces.ed.gov/pubs2004/2004405.pdf",
  "af28f1cc9d91b9f67269fb3009ab269bc746de3572e782b1759f3cb59771e161",
  docs_folder,
  "https://nces.ed.gov/pubs2006/2006344.pdf",
  "0e2dea9236a2a766635e6d20d5d5d30df2d1bddedc123c71c29163435f036aa1",
  docs_folder,
  "https://nces.ed.gov/pubs2006/2006344_4.pdf",
  "d97d18706978a81765ec0deb9cc0b706b7e4bfa1c19622846a3f4f77b8217be2",
  docs_folder,
  "https://nces.ed.gov/pubs2014/2014364.pdf",
  "5b897f7d252eb8529ac492350d93b7c675576af66e6dbcafea1a15d63e8deeed"
)

# R's default 60-second timeout is too short for the 100 MB data file
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
for (archive in files[downloads$folder == data_folder]) {
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
}

message(
  "ELS:2002 files are in ", project_path(data_folder),
  ", documentation in ", project_path(docs_folder)
)

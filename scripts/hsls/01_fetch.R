# Download the HSLS:09 public-use files and documentation from NCES.
#
# Run from the project root:  Rscript scripts/hsls/01_fetch.R
#
# By downloading, you accept the NCES data usage agreement: use the data for
# statistical purposes only, make no attempt to identify anyone, and do not
# link it to individually identifiable data.
#
# shared/data_locations.csv lists every file, with its SHA-256. The data go
# under inputs/raw and stay out of git. The documentation goes under
# inputs/raw, which git also ignores because the PDFs are large.

library(framework)
scaffold()

fetch_data("hsls")

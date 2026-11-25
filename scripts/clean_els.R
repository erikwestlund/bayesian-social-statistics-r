# Build the ELS:2002 analysis file: run every step in scripts/els/ in order.
#
# Run from the project root:  Rscript scripts/clean_els.R
#
# Each step is a script that also runs on its own. A step that fails stops
# the run, so later steps never read a half-built file.

steps <- sort(list.files("scripts/els", pattern = "^[0-9]+_.*\\.R$", full.names = TRUE))
for (step in steps) {
  message("Running ", step)
  source(step, local = new.env())
}

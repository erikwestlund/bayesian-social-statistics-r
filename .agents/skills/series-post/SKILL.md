---
name: series-post
description: Use when starting, building, or finishing a post in the Bayesian Social Statistics series. Covers the build order (R/Stan/Quarto first, then the companion StatsLab section, then the Python and Stata ports), the outline notebook style, data conventions, and how the lab must match the notebook.
---

# Series post

Each post is built in three steps, in this order. Do not start a step before
the one before it is done.

## 1. Build in R, Stan, and Quarto

The R project (`bayesian-social-statistics-r`) is the source of every number
in the series.

- One Quarto notebook per post, in a numbered folder per part of the series:
  `notebooks/01-simple-regression/01-priors.qmd`. Unplaced material goes in
  `notebooks/drafts/`.
- Fit models with brms on the cmdstanr backend. Write Stan by hand only when
  brms cannot express the model.
- Read data with Framework conventions: a catalog entry in
  `settings/data.yml`, `data_read()` in the notebook, and a numbered script in
  `scripts/<dataset>/` that builds or fetches the file with `data_save()`.
- This project cleans the data for the whole series. Each data set has a
  folder of numbered steps and a runner: `scripts/clean_els.R` runs
  `scripts/els/01_fetch.R` and `scripts/els/02_clean.R`, driven by
  `inputs/public/raw/els_crosswalk.csv`, and the result lands in
  `inputs/private/final/els_clean.csv`. HSLS:09 follows the same pattern
  (`scripts/clean_hsls.R`, `scripts/hsls/`). The Python and Stata projects
  have the same steps (`scripts/els/*.py`, `do/els/*.do`) from the same
  crosswalk, and must build the same values: compare each port's
  `els_clean.csv` with this project's column by column after any change.
- Data flow one way: from this project to the lab. The lab loads the cleaned
  files R writes. Never fetch data back from the lab.
- Reusable code goes in `functions/` (for example `functions/regression.R`),
  not in notebook chunks. Notebooks call the helpers.
- Project setup belongs to `scaffold()`, not the setup chunk: seed and
  ggplot theme in `settings/scaffold.yml`, attached packages in
  `settings/packages.yml`, anything else (such as the palette) in
  `scaffold.R`. A notebook's setup chunk is `library(framework)` and
  `scaffold()`.
- Fix every random seed, so the notebook and the lab can show the same
  subsamples.

### One step at a time

Each post introduces one idea and stops. Leave anything that belongs to a
later post out entirely, even when it is easy to show: how the posterior is
computed (grids, samplers), how much information a prior carries, prior
predictive checks, diagnostics. Erik decides what each post covers.

### Outline style

Erik writes the prose. The notebook is an outline:

- Sections with descriptive noun headings, such as Data, Measures, OLS model,
  Bayes with a flat prior.
- In each section: code, its output, then short factual bullets.
- Bullets state facts: estimates, sample sizes, settings, sources. No
  interpretation, transitions, or commentary.
- Every number in a bullet comes from inline R (`` `r ...` ``), never typed
  by hand.
- R names are lowercase snake case. No all-caps constants.
- Transformed variables carry a suffix: `_z` for standardized (mean 0,
  SD 1), `_c` for centered only (mean 0, original units). For example
  `parent_ses_z`, `math_c`.

### Prose that gets published

Erik writes the post prose. Any prose that is published (post text, artifact
titles and descriptions, captions, lab page text) goes through Gemini 4 Neon
first, at minimum: see "Publishing prose" in AGENTS.md.

### Before handing back

- Render with `quarto render notebooks/<part>/<post>.qmd` from the project root.
- Check the rendered output for warnings and errors.
- Look at every figure.
- Share the rendered page through its tunnel URL, not a file path.

## 2. Build the companion StatsLab section

Each post gets a small series of interactive pages at lab.phpstats.org
(`~/Projects/lab.phpstats.org`, Laravel and PHP). Readers change the inputs,
such as the prior or the sample size, and watch the estimates and figures
change.

- Each page makes one point from the post.
- All state is in the URL, so the post can link to an exact example.
- The lab loads the cleaned files this project writes, such as
  `inputs/private/final/els_clean.csv`. It does not clean data itself.
- Each page's default state reproduces a number in the R notebook. Record the
  reference numbers and check them in the lab's tests.
- When the lab simplifies the model, such as fixing the residual SD to get an
  exact posterior, the page says so.
- Results are cached in Redis, keyed by data version, page, and parameters.

## 3. Port to Python and Stata

Only after Erik says the post and its lab are final.

- Python (`bayesian-social-statistics-python`): Bambi or cmdstanpy.
- Stata (`bayesian-social-statistics-stata`): `bayes:` or `bayesmh`.
- Ports reproduce the R notebook's numbers up to Monte Carlo error, from the
  same data file and the same seeds where the software allows.
- Ports follow the same outline and section names as the R notebook.

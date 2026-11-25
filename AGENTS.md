# bayesian-social-statistics-r

This file provides guidance to AI assistants working with this Framework project.
It is the canonical context file; detailed workflow instructions live in the
skills listed below. Edit the sections without regeneration markers freely -
they won't be overwritten.


This project uses public-use data (HSLS:09 and ELS:2002 from NCES). It is a standard Framework project, not a sensitive one. `.gitignore` keeps the NCES files, the cleaned data, and rendered outputs out of git, and says why for each. Never print individual rows; summaries, models, and figures are fine.

## Skills

Detailed instructions live in skill files, loaded on demand. Claude Code discovers
them automatically; other agents should read the relevant SKILL.md before working
on a matching task.

| Skill | Covers | Path |
|-------|--------|------|
| `framework-sensitive-data` | private and public folders in a privacy-sensitive project | `.agents/skills/framework-sensitive-data/SKILL.md` |
| `ggplot2-figures` | accurate ggplot2 figures, from exploring data to publication | `.agents/skills/ggplot2-figures/SKILL.md` |
| `writing` | Use before writing or editing any prose in a data analysis project - text about results, notebook text, captions, READMEs, summaries, or messages that explain findings. Covers a plain register, stating numbers with their uncertainty, claims that match the design, consistent names, headings, and banned patterns. It governs how sentences read; for building and publishing a report, use framework-reports. | `.agents/skills/writing/SKILL.md` |
| `identifiable-data` | Use when an analysis handles identifiable, confidential, or restricted data, including logs, summaries, intermediate files, and output disclosure. | `.agents/skills/identifiable-data/SKILL.md` |
| `checking-data` | Use when validating an analysis dataset, testing join assumptions, or investigating inconsistent counts, ranges, keys, and missingness. | `.agents/skills/checking-data/SKILL.md` |
| `cleaning-data` | Use when transforming raw observations into analysis data, including parsing, recoding, joins, reshaping, and missing-value decisions. | `.agents/skills/cleaning-data/SKILL.md` |
| `git-workflow` | Use when reviewing changes, committing analysis work, resolving merge conflicts, or coordinating branches in a research repository. | `.agents/skills/git-workflow/SKILL.md` |
| `quarto-documents` | Use when creating or editing Quarto documents, including YAML options, executable cells, cross-references, citations, and rendering for R or Python. | `.agents/skills/quarto-documents/SKILL.md` |
| `series-post` | Use when starting, building, or finishing a post in the series: build order (R/Stan/Quarto, then the StatsLab section, then the Python and Stata ports), outline notebook style, data conventions, lab matching. | `.agents/skills/series-post/SKILL.md` |

## Framework Environment <!-- @framework:regenerate -->

This project uses the Framework R package. Follow its conventions in code
that calls `scaffold()`. Leave existing code as it is unless the user asks you
to change it.

### scaffold()

Start each notebook and script with `scaffold()`. It:

1. Sets the working directory to the project root
2. Loads environment variables from `.env`
3. Installs missing packages listed in the settings
4. Attaches packages marked `auto_attach: true`
5. Sources the functions in `functions/`
6. Sets the random seed to 2026
7. Sets the ggplot2 theme to `theme_minimal()`

### Conventions

- Packages marked `auto_attach` are already loaded. Call `library()` only for the others.
- Call functions from `functions/` directly. `scaffold()` has already sourced them.
- Prefer the project's seed. When an operation needs its own seed, say why in a comment.
- Ask before running a database statement that changes data.
- Ask before publishing anything public. GitHub Pages is public even from a private repository.

## Installed Packages <!-- @framework:regenerate -->

**Auto-attached** (loaded by scaffold): dplyr, ggplot2, tidyr, stringr, readr, tibble, forcats, brms
**Installed** (call library() when needed): purrr, lubridate, cmdstanr, posterior, haven, dagitty, survey

Add packages with `package_add("name")` or `package_add("name", auto_attach = TRUE)`.

## Data Management <!-- @framework:regenerate -->

Prefer `data_read()` and `data_save()` for project data. They record a hash
of each file. This project's data directories:

| Purpose | Directory |
|---------|-----------|
| Raw data (immutable) | `inputs/raw/` |
| Intermediate/cleaned data | `inputs/intermediate/` |
| Analysis-ready data | `inputs/final/` |
| Output tables | `outputs/tables/` |
| Output figures | `outputs/figures/` |
| Saved models | `outputs/models/` |
| Reports | `outputs/reports/` |

## Data Out of Git

Nothing in this project is confidential. `.gitignore` names each folder that
stays out of git and why: the NCES downloads (`inputs/raw/els/`,
`inputs/raw/hsls/`) and documentation PDFs, the cleaned data
(`inputs/intermediate/`, `inputs/final/`), and rendered outputs (`outputs/`).


## Project Notes

*Add your project-specific notes, conventions, and documentation here.*
*This section is never modified by `ai_regenerate_context()`.*

### Publishing prose

Any prose that is published, anywhere, goes through Gemini 4 Neon first, at
minimum. That covers blog posts, artifact titles and descriptions, DAG and
figure captions, lab page text, and README text that ships. Send the exact text
with the facts it rests on (start a child task with provider
`antigravity_antigravity_api`, model `gemini-4-neon`), ask for a revision, a list
of changes, and anything factually questionable, then use its revision or
explain to Erik why not. Show Erik what Neon said. Text written after Neon's
review goes back through Neon before it is published.

### Series workflow

Every post is built in three steps, in this order:

1. Build in R, Stan, and Quarto, in this project. It is the source of every number in the series.
2. Build the companion StatsLab section at lab.phpstats.org (`~/Projects/lab.phpstats.org`).
3. When Erik says the post is final, port it to Python and Stata.

The `series-post` skill has the details.


# bayesian-social-statistics-r

This file provides guidance to AI assistants working with this Framework project.
It is the canonical context file; detailed workflow instructions live in the
skills listed below. Edit the sections without regeneration markers freely -
they won't be overwritten.


This project holds restricted data. Do not read or print files in `inputs/private/`, `outputs/private/`. Work from the data dictionary and simulated data instead.

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
6. Sets the random seed to 123

### Conventions

- Packages marked `auto_attach` are already loaded. Call `library()` only for the others.
- Call functions from `functions/` directly. `scaffold()` has already sourced them.
- Prefer the project's seed. When an operation needs its own seed, say why in a comment.
- Ask before running a database statement that changes data.
- Ask before publishing anything public. GitHub Pages is public even from a private repository.


## Installed Packages <!-- @framework:regenerate -->

**Auto-attached** (loaded by scaffold): dplyr, ggplot2, tidyr, stringr, readr, tibble, forcats
**Installed** (call library() when needed): purrr, lubridate

Add packages with `package_add("name")` or `package_add("name", auto_attach = TRUE)`.

## Data Management <!-- @framework:regenerate -->

Prefer `data_read()` and `data_save()` for project data. They record a hash
of each file. This project's data directories:

| Purpose | Directory |
|---------|-----------|
| Private raw data | `inputs/private/raw/` |
| Public raw data | `inputs/public/raw/` |
| Private intermediate | `inputs/private/intermediate/` |
| Public intermediate | `inputs/public/intermediate/` |
| Private analysis-ready | `inputs/private/final/` |
| Public analysis-ready | `inputs/public/final/` |
| Private tables | `outputs/private/tables/` |
| Public tables | `outputs/public/tables/` |
| Private figures | `outputs/private/figures/` |
| Public figures | `outputs/public/figures/` |


## Private Folders

This project was created as privacy sensitive. Private files go in the
`private/` folders, which Git ignores. The `framework-sensitive-data` skill
describes the folders and the checks Framework runs.


## Project Notes

*Add your project-specific notes, conventions, and documentation here.*
*This section is never modified by `ai_regenerate_context()`.*


# Milestone 4: documentation, release checks, and handoff

## Deliverables

The repository includes a complete README, generated help for all five public
functions and the print method, documented synthetic data, a worked vignette,
a generated Markdown example with its calibration figure, a proposal, and an
individual video guide. Course criteria and unresolved submission details are
mapped in `docs/course_requirements.md`.

`scripts/validate_release.R` runs the unit tests and full source-package check,
including vignette building and execution. It preserves the test summary,
check log, and R session information under `docs/validation/`.

The prepared GitHub Actions workflow runs package checks on pushes and pull
requests using read-only repository permissions. Its upload was rejected by
GitHub because the current token lacks workflow permission. The file is retained
in `docs/ci/` with activation instructions. No CI run is claimed. Fresh
GitHub-install results are recorded in `docs/development_log.md`.

## Acceptance evidence

Local checks passed 212 expectations across 30 test blocks, with no test
failures, unexpected warnings, or skipped tests. R CMD check completed with
0 errors, 0 warnings, and 0 notes. The PDF manual was excluded with --no-manual;
HTML vignette and examples were built and checked.

## Handoff boundary

The package and development evidence can be reviewed now. The students still
need to confirm their group, obtain actual peer/instructor feedback, record each
individual video, and submit through Quercus. No video, peer review, proposal
approval, or course submission is represented as completed by this repository.

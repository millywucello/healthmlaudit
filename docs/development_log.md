# Development milestones and handoff

Development follows HealthMLAudit_Shared_Plan.html. The four-week roadmap was
used as a sequence of deliverables; it does not mean four calendar weeks have
elapsed. All five proposed public functions are implemented, including the
optional Markdown report.

| Step | Deliverable | Evidence | Commit |
|---|---|---|---|
| 1 | Input contract and core metrics | 66 expectations passed at the checkpoint; hand calculations agree | `33f57ad` |
| 2 | Calibration, subgroup summaries, synthetic data | 113 expectations passed at the checkpoint | `0fa06e2` |
| 3 | Bootstrap and report generation | 212 expectations passed after additional independent checks | `e3a9ead` |
| 4 | Documentation, example, CI, and installation | Local package check clean; CI configuration prepared | Current release work |

Each milestone has a detailed record in [milestones/](milestones/):
[core contract](milestones/01_core_contract.md),
[calibration and subgroups](milestones/02_calibration_subgroups.md),
[bootstrap and reporting](milestones/03_bootstrap_reporting.md), and
[release handoff](milestones/04_release_handoff.md).

## Local verification

- R 4.2.3 on macOS arm64.
- 30 test blocks and 212 passed expectations.
- R CMD check: 0 errors, 0 warnings, 0 notes.
- The vignette and examples are built and executed; the PDF manual is excluded.
- The synthetic example uses 400 observations and two groups of 200.
- The generated report and calibration image are reviewed before handoff.

See [release_summary.md](validation/release_summary.md),
[test_results.csv](validation/test_results.csv), and
[package_check.txt](validation/package_check.txt).

## External verification

GitHub rejected the workflow upload because the saved personal access token
lacks the workflow permission. No account permissions were changed. The ready
workflow is in `docs/ci/R-CMD-check.yaml`, with activation instructions. No CI
run is claimed. Fresh GitHub installation is checked after publication and its
result is recorded below.

## Remaining course tasks

A classmate's review, instructor approval, individual video recordings, and
Quercus submission require the students' participation. No completion is claimed
for those tasks. See [course_requirements.md](course_requirements.md) and
[tutorial_video.md](tutorial_video.md).

# Local release validation

Package version: 0.1.0
R version: 4.2.3

Test blocks: 30
Passed expectations: 212
Failed expectations: 0
R CMD check: 0 errors, 0 warnings, 0 notes.

The check builds and executes the vignette and examples. PDF manual creation is excluded with --no-manual.

Independent numerical checks cover pairwise AUROC, hand-calculated confusion rates and Brier score, and paired-row bootstrap percentiles.

CI and fresh GitHub installation are recorded separately in the development log. A successful local check is not a substitute for those results.

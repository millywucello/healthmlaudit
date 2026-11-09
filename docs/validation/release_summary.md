# Local release validation

Package version: 0.1.0
R version: 4.2.3

Test blocks: 30
Passed expectations: 212
Failed expectations: 0
R CMD check: 0 errors, 0 warnings, 0 notes.

The check builds and executes the vignette and examples. PDF manual creation is excluded with --no-manual.

Independent numerical checks cover pairwise AUROC, hand-calculated confusion rates and Brier score, and paired-row bootstrap percentiles.

Fresh GitHub installation passed in a new R session and destination library, including the built vignette and all five public functions.

CI activation is pending because GitHub rejected the active workflow upload: the current token lacks workflow permission. The ready file and instructions are in docs/ci/. No successful CI run is claimed.

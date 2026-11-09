# healthmlaudit

Evaluate binary classification predictions with a consistent positive class,
input checks, and reusable results. Development follows the shared HealthMLAudit
plan. See `docs/milestones/` for the scope and acceptance evidence at each step.

The current core calculates AUROC, accuracy, sensitivity, specificity,
precision, and Brier score. Calibration, subgroup summaries, bootstrap intervals,
and reporting are the next milestones.

```r
remotes::install_github("millywucello/healthmlaudit")
library(healthmlaudit)
x <- data.frame(outcome = c(1, 0, 1, 0), risk = c(.9, .2, .7, .6))
audit_binary(x, "outcome", "risk", positive = 1)$metrics
```

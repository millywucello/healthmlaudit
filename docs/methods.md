# Methods and API decisions

## Input contract

`audit_binary()` accepts a non-empty data frame, string column names, an explicit
positive class, a threshold in [0, 1], and an error-or-omit missingness policy.
Probabilities must be numeric and finite when observed. No automatic clipping
or conversion of probability strings is performed.

Labels are compared as strings. At most two labels may appear after including
the positive label and declared factor levels. In a one-class sample, a supplied
but unobserved positive label is allowed and denotes an all-negative sample.
The function cannot distinguish this situation from a misspelled positive label;
review `metadata$positive` and the event counts. With two observed classes, an
unrecognized positive label raises an error. Unused factor levels count toward
the two-class limit.

Missing truth or probability is an error by default. Explicit omission records
positions and counts. Invalid observed values still fail even if the other
required field is missing. Missing subgroup labels stay in a separate NA group.
Rows with identical values are not deduplicated because no event ID is required.

The audit retains the input rows and settings. Later functions check that the
object was not edited. Rebuild the audit to change its data or threshold.

## Metrics

The internal outcome is 1 for the explicit positive label and 0 otherwise.
Positive predictions use probability >= threshold. Confusion counts are TP,
FP, TN, and FN. Classification measures follow these definitions:

- Accuracy = (TP + TN) / N.
- Sensitivity = TP / (TP + FN).
- Specificity = TN / (TN + FP).
- Precision = TP / (TP + FP).
- Brier = mean((outcome - probability)^2).

AUROC describes the probability that a positive observation receives a higher
score than a negative one, with half credit for ties. Standard calculations use
yardstick with the event set explicitly to the first internal factor level.
The tests independently calculate pairwise AUROC and confusion-matrix rates.

If an outcome class is absent, AUROC is undefined. Zero denominators produce
NA for the corresponding rates. Accuracy and Brier remain defined for a
non-empty one-class sample. Undefined values produce R warnings and stored
messages; they are never silently changed to zero.

## Calibration

Equal-width bins cover [0, 1]. Each includes its lower boundary and excludes
its upper boundary, except that the last includes 1. Empty bins are omitted.
Points use mean predicted probability, observed event proportion, and count.
The returned plot exposes these summaries through `plot$data`.

The small-sample warning below 30 observations is a transparent heuristic,
not a power calculation. The bin count is user-selected. There is no smoothing,
calibration slope estimation, or clinical calibration test in this version.

## Subgroups

Groups share the audit's positive class and threshold. Each row reports both
class counts, prevalence, confusion counts, metrics, and warnings. `min_n` is a
warning threshold only. Group differences are descriptive; prevalence and case
mix may differ, and the package does not identify discrimination or causal bias.

## Bootstrap

Each replicate samples N complete observation indices with replacement and
recalculates the requested metrics. The limits are type-7 empirical quantiles
at (1 - confidence level)/2 and 1 - (1 - confidence level)/2. No normal
approximation, stratification, or bias correction is used.

Undefined values are dropped separately by metric and counted. Fewer than two
valid values gives NA limits. Constant replicates give a zero-width interval
and a warning. Dropping one-class AUROC samples conditions the interval on valid
resamples; many invalid draws are a sign that the interval should not be trusted.

A supplied seed restores the caller's RNG state, including its prior absence.
Reproducibility assumes the same R RNG settings. With seed = NULL the function
uses and advances the current RNG. Bootstrap matrices are retained as an
attribute for inspection.

The method assumes independent observations and conditions on the supplied
predictions and threshold. It does not estimate training, model-selection, or
threshold-selection uncertainty. Repeated observations require a cluster-aware
design that this version does not implement.

## Report files

The Markdown report contains aggregate results and a relative link to its PNG.
It contains no per-observation prediction table. Output files are not replaced
unless overwrite = TRUE. Subgroup and interval results must carry a signature
matching the audit. Share both generated files for the image link to work.

## References

- yardstick AUROC: https://yardstick.tidymodels.org/reference/roc_auc.html
- yardstick Brier score: https://yardstick.tidymodels.org/reference/brier_class.html
- yardstick sensitivity: https://yardstick.tidymodels.org/reference/sens.html
- R quantile documentation: `?stats::quantile`.

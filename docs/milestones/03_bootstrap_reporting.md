# Milestone 3: bootstrap intervals and Markdown reports

## Deliverables

`bootstrap_ci()` resamples complete observations and returns percentile
intervals with requested, valid, and invalid replicate counts. It supports all
six metrics, with AUROC and Brier score selected by default. A supplied seed
restores the caller's RNG state after execution.

`generate_report()` implements the stretch goal. It writes aggregate metrics,
subgroup summaries, intervals, warnings, and a calibration figure. It does not
copy individual prediction rows into the Markdown. Existing files are protected
unless overwrite is explicitly requested. Results from a different audit are
rejected.

## Statistical decisions

The bootstrap is ordinary independent-row resampling with type-7 percentile
quantiles. Undefined resamples are excluded per metric and counted. Fewer than
two valid replicates gives NA limits. Constant replicates receive a warning
about a zero-width interval. This method does not include model-retraining or
threshold-selection uncertainty and does not support clustered records.

## Verification

An independent base-R Brier calculation checks every resampled value and the
interval endpoints. Tests cover seeded reproducibility, RNG preservation,
single-class resamples, invalid arguments, report contents, output files,
protected destinations, and incompatible audit results.

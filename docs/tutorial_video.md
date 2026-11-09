# Individual tutorial video guide

Target length: about four minutes, leaving a buffer below the five-minute limit.
Each student should record their own demonstration and explanation. This file is
a recording guide, not a completed video or evidence of an individual submission.

## 0:00-0:30: purpose

"HealthMLAudit evaluates binary classification predictions that already exist.
It helps me look beyond AUROC by checking classification performance,
calibration, subgroup results, and bootstrap uncertainty. I will use synthetic
observations, not real patient records."

## 0:30-1:20: inputs and metrics

```r
library(healthmlaudit)
head(demo_predictions)
audit <- audit_binary(demo_predictions, "outcome", "predicted_risk",
                       positive = 1, threshold = 0.5)
audit$metrics
```

"There are 400 observations. Outcome 1 is the event, and the probability column
must refer to that event. Predictions at or above 0.5 count as positive.
AUROC summarizes ranking, while accuracy, sensitivity, specificity, and precision
depend on the threshold. Brier score measures probability error. I would check
these counts before interpreting any metric."

## 1:20-2:10: calibration and subgroups

```r
plot_calibration(audit, bins = 8)
groups <- audit_subgroups(audit, "age_group")
groups[c("group", "n", "positive_n", "negative_n", "roc_auc", "brier")]
```

"Each calibration point summarizes one occupied probability bin. Its size shows
how many observations it contains. Below the diagonal, predictions are higher
than the observed event proportion. The group table uses the same settings as
the main audit. A difference between groups does not by itself establish bias."

## 2:10-3:10: bootstrap and errors

```r
intervals <- bootstrap_ci(audit, times = 500, seed = 42)
intervals
bad <- demo_predictions
bad$predicted_risk[1] <- 1.2
try(audit_binary(bad, "outcome", "predicted_risk"))
```

"The bootstrap keeps each outcome and probability paired. It reports how many
resamples were valid for each metric. The seed makes this example repeatable.
These intervals assume independent observations and do not include retraining
the model. Invalid probabilities raise a clear error rather than being clipped."

## 3:10-4:10: report and help

```r
files <- generate_report(audit, groups, intervals,
                          file = "video_audit.md", overwrite = TRUE)
files
?audit_binary
```

"The report collects the results, warnings, and a calibration figure. New users
can install the package from millywucello/healthmlaudit on GitHub, then follow
the README or vignette. I would use it for an auditable evaluation workflow,
while keeping the study design and clinical interpretation outside the package."

## Before recording

Run the code once, clear unrelated objects from view, check the microphone, and
make text readable. Explain an actual value from the current output rather than
memorizing a number that may change. Confirm the recording is under five minutes,
then check the current video deadline and upload instructions in Quercus.

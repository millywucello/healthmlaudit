# Milestone 1: input contract and core metrics

## Scope

Create the package skeleton and a single audit object shared by later modules.
Implement AUROC, accuracy, sensitivity, specificity, precision, and Brier score
using yardstick. The proposed public function names are retained from the plan.

## Decisions

- The positive label is explicit; factor ordering never determines the event.
- Probabilities refer to the chosen positive class. Values at the threshold are
  predicted positive. The package does not choose a threshold.
- Missing truth or probability raises an error unless omission is requested.
  Omitted row positions and counts are retained. Other missing columns stay.
- Single-class samples are allowed. Undefined metrics are NA and produce both
  an R warning and a stored message.
- Identical rows are retained. Observation independence is the user's design
  assumption, not something inferred from matching values.
- Dates, model training, clinical recommendations, and multiclass evaluation
  are outside this version's API.

## Deliverables

`DESCRIPTION`, `R/audit_binary.R`, shared validation helpers, an S3 print method,
roxygen documentation, and tests for numerical accuracy and invalid inputs.

## Acceptance evidence

The four-observation example must return AUROC 1, accuracy 0.75, sensitivity 1,
specificity 0.5, precision 2/3, and Brier score 0.125. Tests also cover ties,
reversed rankings, factor-level order, threshold equality, and missingness.
The executed results are recorded in the release validation log.

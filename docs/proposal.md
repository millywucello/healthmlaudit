# HealthMLAudit: binary prediction evaluation in R

Binary classification results are often reported using AUROC alone. That leaves
other questions unanswered: whether the predicted probabilities agree with
observed outcomes, whether performance differs between subgroups, and how much
uncertainty accompanies the estimates.

We propose `healthmlaudit`, an R package that evaluates supplied outcomes and
positive-class probabilities through one consistent interface. It calculates
AUROC, threshold-based classification metrics, and Brier score. It also provides
binned calibration plots, subgroup summaries, and bootstrap percentile intervals.
A Markdown report brings the results and warnings together for review.

The package uses yardstick for standard metrics and ggplot2 for visualization.
Its contribution is the shared data contract and a reproducible workflow with
clear treatment of missing and undefined values. Tests use hand-calculated
examples and independent numerical checks. Documentation includes help files,
examples, and a tutorial using synthetic predictions.

The project covers binary model evaluation. Model fitting, clinical decisions,
fairness certification, and multiclass support are outside its scope. Bootstrap
intervals assume independent evaluation observations and do not include model
retraining uncertainty.

The deliverables are an installable GitHub package, documented functions,
reproducible tests and checks, a worked example, and an individual tutorial video
from each group member. This proposal and the package are prepared for review;
instructor approval and proposal submission have not been recorded here.

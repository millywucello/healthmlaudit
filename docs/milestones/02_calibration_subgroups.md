# Milestone 2: calibration and subgroup analysis

## Deliverables

`plot_calibration()` returns an editable ggplot with bin counts and observed
rates in its data. `audit_subgroups()` returns per-group performance, event
counts, prevalence, threshold, and diagnostic messages. The synthetic example
contains 400 observations with two group labels and intentionally shifted
predictions. Its generating script is included.

## Statistical decisions

Equal-width bins include their lower endpoint; the last bin also includes 1.
Empty intervals are omitted without adding artificial zero event rates. Bin
counts control point size. Samples below 30 receive a descriptive warning.

Subgroups use the same positive label and threshold as the parent audit.
Missing subgroup labels form their own NA group; unused factor levels do not
produce empty groups. Small and single-class groups remain visible. Their
warnings distinguish low sample size from mathematically undefined metrics.
The min_n cutoff is not a sample-size recommendation.

## Verification

Tests use explicit bin membership and hand-calculated subgroup values, check
0/1 endpoints and empty bins, and ensure grouped counts sum to the retained
sample. No substantive claim about health disparities or fairness is made.

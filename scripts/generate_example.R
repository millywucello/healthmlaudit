# Run from the package root after devtools::load_all() or installation.
if (!requireNamespace("healthmlaudit", quietly = TRUE)) stop("Install or load healthmlaudit first.")
with(healthmlaudit::demo_predictions, stopifnot(length(outcome) == 400L))
audit <- healthmlaudit::audit_binary(healthmlaudit::demo_predictions,
  "outcome", "predicted_risk", positive = 1)
groups <- healthmlaudit::audit_subgroups(audit, "age_group")
ci <- healthmlaudit::bootstrap_ci(audit, times = 500, seed = 42)
healthmlaudit::generate_report(audit, groups, ci, file = "docs/example_audit.md", overwrite = TRUE)
write.csv(audit$metrics, "docs/validation/example_metrics.csv", row.names = FALSE)
write.csv(as.data.frame(groups), "docs/validation/example_subgroups.csv", row.names = FALSE)
write.csv(as.data.frame(ci), "docs/validation/example_intervals.csv", row.names = FALSE)

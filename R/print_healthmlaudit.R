#' Print a binary prediction audit
#'
#' @param x A `healthmlaudit` object.
#' @param ... Additional arguments passed to `print.data.frame()`.
#' @return `x`, invisibly.
#' @examples
#' print(audit_binary(demo_predictions, "outcome", "predicted_risk"))
#' @export
print.healthmlaudit <- function(x, ...) {
  .check_audit(x)
  cat("Binary prediction audit\n")
  cat("Positive class:", x$metadata$positive, "| Threshold:", x$metadata$threshold, "\n")
  cat("Used:", x$metadata$n_used, "of", x$metadata$n_input, "observations\n")
  print(x$metrics, row.names = FALSE, ...)
  if (length(x$warnings)) cat("Warnings:\n", paste0("- ", x$warnings, collapse = "\n"), "\n", sep = "")
  invisible(x)
}

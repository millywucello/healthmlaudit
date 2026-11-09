#' Summarize binary prediction performance by subgroup
#'
#' Reuse the audit's positive class and threshold in each observed subgroup.
#'
#' @param audit An object from [audit_binary()].
#' @param group A character string naming a categorical column in `audit$data`.
#'   Character, factor, logical, and numeric group codes are accepted.
#' @param min_n Positive integer used to flag small groups. Defaults to 30.
#'   This warning threshold is not a guarantee of statistical precision.
#' @return A data frame containing `group`, `is_missing_group`, `n`,
#'   `positive_n`, `negative_n`, `prevalence`, confusion counts, all six metrics,
#'   `threshold`, and a `warnings` column. Missing group labels form their own
#'   NA group. Unused factor levels are omitted. Attributes retain the grouping
#'   variable and audit signature for [generate_report()].
#' @details Results describe the retained audit observations. Rows previously
#'   omitted by [audit_binary()] are not reintroduced. A small or single-class
#'   group is retained, and undefined metrics remain NA. Any issue produces one
#'   R warning; the row-level warnings identify affected groups. Differences
#'   between groups do not establish bias, unfairness, or a causal effect.
#' @examples
#' audit <- audit_binary(demo_predictions, "outcome", "predicted_risk")
#' audit_subgroups(audit, "age_group")
#' @export
audit_subgroups <- function(audit, group, min_n = 30) {
  .check_audit(audit)
  .check_string(group, "group")
  if (!group %in% names(audit$data)) .stop(paste("Missing group column:", group))
  .check_number(min_n, "min_n", 1, .Machine$integer.max, integer = TRUE)
  x <- audit$data[[group]]
  if (!(is.character(x) || is.factor(x) || is.logical(x) || is.numeric(x)) || !is.null(dim(x)) || is.complex(x)) {
    .stop("group must contain scalar categorical labels.")
  }
  if (is.numeric(x) && any(!is.finite(x[!is.na(x)]))) .stop("group contains non-finite labels.")
  x <- as.character(x)
  if (any(!nzchar(trimws(x[!is.na(x)])))) .stop("group contains empty labels; use NA for missing groups.")
  labels <- unique(x)
  group_id <- match(x, labels)
  result <- do.call(rbind, lapply(seq_along(labels), function(i) {
    rows <- which(group_id == i)
    computed <- .compute_metrics(audit$.outcome[rows], audit$.probability[rows], audit$metadata$threshold)
    messages <- computed$warnings
    if (length(rows) < min_n) messages <- c(paste0("Group size ", length(rows), " is below min_n = ", min_n, "."), messages)
    if (is.na(labels[i])) messages <- c("Missing subgroup labels retained as a separate group.", messages)
    data.frame(group = labels[i], is_missing_group = is.na(labels[i]), computed$metrics,
               threshold = audit$metadata$threshold, warnings = paste(messages, collapse = " "),
               stringsAsFactors = FALSE)
  }))
  rownames(result) <- NULL
  attr(result, "group_variable") <- group
  attr(result, "audit_signature") <- audit$.signature
  class(result) <- c("healthml_subgroups", "data.frame")
  if (any(nzchar(result$warnings))) warning("Subgroup issues were found; inspect the warnings column.", call. = FALSE)
  result
}

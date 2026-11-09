#' Bootstrap confidence intervals for audit metrics
#'
#' Resample complete outcome-probability pairs with replacement and calculate
#' percentile intervals for selected metrics.
#'
#' @param audit An object from [audit_binary()].
#' @param metrics A non-empty character vector of distinct names chosen from
#'   `roc_auc`, `accuracy`, `sensitivity`, `specificity`, `precision`, and `brier`.
#' @param times Integer number of resamples, from 2 to 1000000. Defaults to 500.
#' @param conf_level Confidence level strictly between 0 and 1.
#' @param seed NULL or an integer from 0 to `.Machine$integer.max`. A supplied
#'   seed makes the run reproducible under the same R RNG settings and restores
#'   the caller's random-number state afterward. NULL consumes the current RNG.
#' @return A data frame with metric, original estimate, lower and upper limits,
#'   confidence level, requested, valid, and invalid replicate counts, seed, and
#'   warnings. Attribute `replicates` contains the resampled metric values;
#'   `audit_signature` links the result to its input audit.
#' @details Intervals use [stats::quantile()] with type 7. Undefined replicates
#'   are counted and excluded separately for each metric. AUROC is undefined in
#'   one-class resamples. Fewer than two valid replicates gives NA interval limits.
#'   Constant replicates produce a zero-width interval and an explanatory warning.
#'
#'   This ordinary row bootstrap assumes independent evaluation observations.
#'   It is unsuitable for repeated or clustered patient observations without a
#'   different resampling design. It quantifies uncertainty conditional on the
#'   supplied predictions and threshold, not uncertainty from retraining or
#'   threshold selection. Few resamples, rare events, and dropped replicates can
#'   make percentile intervals unreliable.
#' @examples
#' a <- audit_binary(demo_predictions, "outcome", "predicted_risk")
#' bootstrap_ci(a, times = 100, seed = 42)
#' @export
bootstrap_ci <- function(audit, metrics = c("roc_auc", "brier"), times = 500,
                         conf_level = .95, seed = 42) {
  .check_audit(audit)
  supported <- c("roc_auc", "accuracy", "sensitivity", "specificity", "precision", "brier")
  if (!is.character(metrics) || !length(metrics) || anyNA(metrics) ||
      anyDuplicated(metrics) || any(!metrics %in% supported)) {
    .stop(paste("metrics must be distinct names from:", paste(supported, collapse = ", ")))
  }
  .check_number(times, "times", 2, 1000000, integer = TRUE)
  .check_number(conf_level, "conf_level", 0, 1)
  if (conf_level == 0 || conf_level == 1) .stop("conf_level must be strictly between 0 and 1.")
  if (!is.null(seed)) .check_number(seed, "seed", 0, .Machine$integer.max, integer = TRUE)
  values <- .with_seed(seed, {
    result <- matrix(NA_real_, nrow = times, ncol = length(metrics), dimnames = list(NULL, metrics))
    for (b in seq_len(times)) {
      rows <- sample.int(length(audit$.outcome), replace = TRUE)
      m <- .compute_metrics(audit$.outcome[rows], audit$.probability[rows], audit$metadata$threshold)$metrics
      result[b, ] <- unlist(m[metrics], use.names = FALSE)
    }
    result
  })
  alpha <- (1 - conf_level) / 2
  result <- do.call(rbind, lapply(metrics, function(metric) {
    v <- values[, metric]
    valid <- v[is.finite(v)]
    messages <- character()
    if (length(valid) < times) messages <- c(messages,
      paste(times - length(valid), "undefined resamples excluded for", metric))
    limits <- c(NA_real_, NA_real_)
    if (length(valid) >= 2L) {
      limits <- as.numeric(stats::quantile(valid, c(alpha, 1-alpha), type = 7, names = FALSE))
      if (length(unique(valid)) == 1L) messages <- c(messages, "Replicates are constant; the interval has zero width.")
    } else messages <- c(messages, "Fewer than two valid resamples; interval limits are NA.")
    data.frame(metric = metric, estimate = audit$metrics[[metric]], lower = limits[1], upper = limits[2],
      conf_level = conf_level, n_requested = times, n_valid = length(valid),
      n_invalid = times - length(valid), seed = if (is.null(seed)) NA_integer_ else as.integer(seed),
      warnings = paste(messages, collapse = ". "), stringsAsFactors = FALSE)
  }))
  attr(result, "replicates") <- values
  attr(result, "audit_signature") <- audit$.signature
  class(result) <- c("healthml_bootstrap", "data.frame")
  issues <- result$warnings[nzchar(result$warnings)]
  .signal_warnings(issues)
  result
}

.with_seed <- function(seed, code) {
  if (is.null(seed)) return(force(code))
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) previous <- get(".Random.seed", envir = globalenv())
  on.exit({
    if (had_seed) assign(".Random.seed", previous, envir = globalenv()) else
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  })
  set.seed(seed)
  force(code)
}

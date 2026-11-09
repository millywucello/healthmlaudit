#' Evaluate binary classification predictions
#'
#' Validate observed labels and positive-class probabilities, then calculate
#' AUROC, accuracy, sensitivity, specificity, precision, and Brier score.
#'
#' @param data A non-empty data frame. Additional columns are retained for
#'   subgroup analysis.
#' @param truth,prob Character strings naming the outcome and probability
#'   columns. Labels may be numeric, logical, character, or factor. Probabilities
#'   must be numeric, finite when observed, and between 0 and 1.
#' @param positive One label denoting the event class. The probability column
#'   must contain probabilities of this class, even when its factor level comes
#'   last. Labels are compared as strings. Defaults to `1`.
#' @param threshold A number in `[0, 1]`. Probabilities greater than or equal
#'   to the threshold are classified as positive. Defaults to `0.5`.
#' @param na_action Either `"error"` (default) or `"omit"`. Omission applies only
#'   to rows missing truth or probability and is recorded in the metadata.
#'
#' @return A `healthmlaudit` object containing a single-row `metrics` data frame,
#'   retained `data`, `metadata` (column names, class labels, threshold, input and
#'   retained counts, omitted row positions), and character `warnings`.
#'   The metric row also contains `n`, `positive_n`, `negative_n`, `prevalence`,
#'   and confusion counts `tp`, `fp`, `tn`, `fn`.
#'
#' @details Metrics use the explicitly named positive class. AUROC gives ties
#'   half credit. Brier score is `mean((outcome - probability)^2)` for a 0/1
#'   event indicator. Undefined AUROC or zero-denominator rates are `NA` with a
#'   warning. One-class data are allowed; with only one observed class, an
#'   absent positive label denotes an all-negative sample. Unused factor levels
#'   count toward the two-class limit.
#'
#'   Evaluate held-out or otherwise appropriate predictions. The function does
#'   not check how predictions were obtained, train a model, or select a
#'   threshold. Duplicate rows are retained because no observation identifier
#'   is required. Users must assess independence before resampling.
#'
#' @examples
#' x <- data.frame(outcome = c(1, 0, 1, 0), risk = c(.9, .2, .7, .6))
#' audit <- audit_binary(x, "outcome", "risk", positive = 1)
#' audit$metrics
#' audit_binary(demo_predictions, "outcome", "predicted_risk")
#' @export
audit_binary <- function(data, truth, prob, positive = 1, threshold = 0.5,
                          na_action = "error") {
  checked <- .validate_inputs(data, truth, prob, positive, threshold, na_action)
  computed <- .compute_metrics(checked$outcome, checked$probability, threshold)
  messages <- computed$warnings
  if (length(checked$omitted)) messages <- c(
    paste(length(checked$omitted), "rows with missing truth or probability were omitted."), messages)
  result <- structure(list(
    metrics = computed$metrics, data = checked$data,
    metadata = list(truth = truth, prob = prob, positive = checked$positive,
      negative = checked$negative, threshold = threshold, na_action = na_action,
      n_input = nrow(data), n_used = nrow(checked$data),
      n_omitted = length(checked$omitted), omitted_rows = checked$omitted),
    warnings = messages, .outcome = checked$outcome, .probability = checked$probability
  ), class = "healthmlaudit")
  result$.signature <- .audit_signature(result)
  .signal_warnings(messages)
  result
}

.compute_metrics <- function(y, probability, threshold) {
  event <- factor(ifelse(y == 1, "event", "none"), levels = c("event", "none"))
  prediction <- factor(ifelse(probability >= threshold, "event", "none"), levels = levels(event))
  tp <- sum(y == 1 & probability >= threshold)
  fp <- sum(y == 0 & probability >= threshold)
  tn <- sum(y == 0 & probability < threshold)
  fn <- sum(y == 1 & probability < threshold)
  messages <- character()
  auc <- sensitivity <- specificity <- precision <- NA_real_
  if (length(unique(y)) == 2L) {
    auc <- yardstick::roc_auc_vec(event, probability, event_level = "first")
  } else messages <- c(messages, "AUROC is undefined because only one outcome class is present.")
  if (tp + fn > 0L) sensitivity <- yardstick::sens_vec(event, prediction, event_level = "first") else
    messages <- c(messages, "Sensitivity is undefined because no positive outcomes are present.")
  if (tn + fp > 0L) specificity <- yardstick::spec_vec(event, prediction, event_level = "first") else
    messages <- c(messages, "Specificity is undefined because no negative outcomes are present.")
  if (tp + fp > 0L) precision <- yardstick::precision_vec(event, prediction, event_level = "first") else
    messages <- c(messages, "Precision is undefined because no observations are predicted positive.")
  list(metrics = data.frame(n = length(y), positive_n = sum(y == 1), negative_n = sum(y == 0),
    prevalence = mean(y), tp = tp, fp = fp, tn = tn, fn = fn, roc_auc = auc,
    accuracy = yardstick::accuracy_vec(event, prediction), sensitivity = sensitivity,
    specificity = specificity, precision = precision,
    brier = yardstick::brier_class_vec(event, probability, event_level = "first")), warnings = messages)
}

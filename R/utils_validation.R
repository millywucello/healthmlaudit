.stop <- function(message) stop(message, call. = FALSE)

.check_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    .stop(paste0(name, " must be one non-empty character string."))
  }
}

.check_number <- function(x, name, lower, upper, integer = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < lower || x > upper || (integer && x != floor(x))) {
    .stop(paste0(name, " must be ", if (integer) "an integer" else "a number",
                 " between ", lower, " and ", upper, "."))
  }
}

.signal_warnings <- function(messages) {
  if (length(messages)) warning(paste(unique(messages), collapse = "\n"), call. = FALSE)
}

.validate_inputs <- function(data, truth, prob, positive, threshold, na_action) {
  if (!is.data.frame(data) || !nrow(data)) .stop("data must be a non-empty data frame.")
  if (anyDuplicated(names(data)) || anyNA(names(data)) || any(!nzchar(names(data)))) {
    .stop("data must have unique, non-empty column names.")
  }
  .check_string(truth, "truth")
  .check_string(prob, "prob")
  if (truth == prob) .stop("truth and prob must name different columns.")
  missing_columns <- setdiff(c(truth, prob), names(data))
  if (length(missing_columns)) .stop(paste("Missing columns:", paste(missing_columns, collapse = ", ")))
  .check_number(threshold, "threshold", 0, 1)
  if (!is.character(na_action) || length(na_action) != 1L || is.na(na_action) ||
      !na_action %in% c("error", "omit")) .stop('na_action must be "error" or "omit".')
  y <- data[[truth]]
  if (!(is.character(y) || is.factor(y) || is.numeric(y) || is.logical(y)) ||
      !is.null(dim(y))) .stop("truth must contain scalar binary labels.")
  if (is.numeric(y) && any(!is.finite(y[!is.na(y)]))) .stop("truth contains non-finite labels.")
  if (length(positive) != 1L || is.na(positive) ||
      !(is.character(positive) || is.numeric(positive) || is.logical(positive)) ||
      !is.null(dim(positive)) || !nzchar(trimws(as.character(positive))) ||
      (is.numeric(positive) && !is.finite(positive))) {
    .stop("positive must be one non-missing label.")
  }
  labels <- as.character(y)
  positive <- as.character(positive)
  if (any(!nzchar(trimws(labels[!is.na(labels)])))) .stop("truth contains empty labels.")
  declared <- if (is.factor(y)) levels(y) else character()
  domain <- unique(c(labels[!is.na(labels)], declared, positive))
  if (length(domain) > 2L) {
    .stop("truth must be binary and positive must identify one of its classes.")
  }
  risk <- data[[prob]]
  if (!is.numeric(risk) || !is.null(dim(risk))) .stop("prob must be a numeric probability column.")
  if (any(!is.finite(risk[!is.na(risk)])) || any(risk < 0 | risk > 1, na.rm = TRUE)) {
    .stop("prob must contain finite probabilities between 0 and 1.")
  }
  omitted <- which(is.na(y) | is.na(risk))
  if (length(omitted) && na_action == "error") {
    .stop(paste0(length(omitted), ' rows have missing truth or probability; use na_action = "omit" to remove them.'))
  }
  keep <- setdiff(seq_len(nrow(data)), omitted)
  if (!length(keep)) .stop("No observations remain after removing missing truth or probability.")
  # Missing subgroup labels are retained and handled by audit_subgroups().
  list(data = data[keep, , drop = FALSE], outcome = as.integer(labels[keep] == positive),
       probability = risk[keep], positive = positive, negative = setdiff(domain, positive),
       omitted = omitted)
}

.audit_signature <- function(audit) {
  serialize(list(audit$data, audit$metadata, audit$metrics, audit$warnings), NULL, version = 2)
}

.check_audit <- function(audit) {
  if (!inherits(audit, "healthmlaudit") || !is.list(audit) ||
      !all(c("data", "metadata", "metrics", ".outcome", ".probability", ".signature") %in% names(audit))) {
    .stop("audit must be an object returned by audit_binary().")
  }
  if (!identical(audit$.signature, .audit_signature(audit)) ||
      !identical(as.numeric(audit$.probability), as.numeric(audit$data[[audit$metadata$prob]])) ||
      !identical(audit$.outcome, as.integer(as.character(audit$data[[audit$metadata$truth]]) == audit$metadata$positive))) {
    .stop("The audit inputs or settings have changed; rebuild it with audit_binary().")
  }
  invisible(audit)
}

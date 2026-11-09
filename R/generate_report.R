#' Save a Markdown prediction-audit report
#'
#' Write aggregate results and a calibration PNG beside a Markdown report.
#' Individual observations are not copied into the report.
#'
#' @param audit An object from [audit_binary()].
#' @param subgroup_result NULL or an unmodified result from [audit_subgroups()]
#'   for the same audit.
#' @param ci_result NULL or a result from [bootstrap_ci()] for the same audit.
#' @param file Markdown output path ending in `.md`. The parent directory must
#'   exist. The figure uses the same stem followed by `_calibration.png`.
#' @param overwrite Whether to replace existing output files. Defaults to FALSE.
#' @return Invisibly, a named list of absolute report and figure paths.
#' @details Warnings from the audit, subgroup results, intervals, and calibration
#'   plot are included. The report states the positive class, threshold,
#'   missingness, and bootstrap limitations. Labels are escaped for Markdown.
#'   Subgroup and interval objects must originate from the same audit inputs and
#'   settings. A report is a descriptive summary, not clinical validation.
#' @examples
#' a <- audit_binary(demo_predictions, "outcome", "predicted_risk")
#' g <- audit_subgroups(a, "age_group")
#' output <- generate_report(a, g, file = tempfile(fileext = ".md"))
#' file.exists(output$report)
#' @export
generate_report <- function(audit, subgroup_result = NULL, ci_result = NULL,
                             file = "model_audit.md", overwrite = FALSE) {
  .check_audit(audit)
  .check_string(file, "file")
  if (!grepl("\\.md$", file, ignore.case = TRUE)) .stop("file must end in .md.")
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) .stop("overwrite must be TRUE or FALSE.")
  .check_related_result(subgroup_result, "healthml_subgroups", audit, "subgroup_result")
  .check_related_result(ci_result, "healthml_bootstrap", audit, "ci_result")
  file <- path.expand(file)
  if (!dir.exists(dirname(file))) .stop("The report's parent directory does not exist.")
  report <- file.path(normalizePath(dirname(file), winslash = "/"), basename(file))
  figure <- sub("\\.md$", "_calibration.png", report, ignore.case = TRUE)
  if (dir.exists(report) || dir.exists(figure)) .stop("An output path names a directory.")
  if (!overwrite && any(file.exists(c(report, figure)))) .stop("Output already exists; use overwrite = TRUE to replace it.")
  if (file.access(dirname(report), mode = 2) != 0L) .stop("The report directory is not writable.")
  plot <- suppressWarnings(plot_calibration(audit))
  notes <- unique(c(audit$warnings, attr(plot, "audit_warnings"),
    if (!is.null(subgroup_result)) subgroup_result$warnings,
    if (!is.null(ci_result)) ci_result$warnings))
  notes <- notes[!is.na(notes) & nzchar(notes)]
  metrics <- data.frame(metric = names(audit$metrics), value = unlist(audit$metrics, use.names = FALSE))
  lines <- c("# Binary prediction audit", "",
    paste0("Positive class: ", .md_escape(audit$metadata$positive),
      ". Classification threshold: ", audit$metadata$threshold, " (probability >= threshold)."), "",
    paste0("Observations used: ", audit$metadata$n_used, " of ", audit$metadata$n_input,
      ". Omitted for missing truth or probability: ", audit$metadata$n_omitted, "."), "",
    "## Performance", "", .md_table(metrics), "",
    "AUROC measures ranking; Brier score is mean squared probability error. Classification metrics depend on the stated threshold. NA means undefined, not zero.", "",
    "## Calibration", "", paste0("![Binned calibration](", utils::URLencode(basename(figure), reserved = TRUE), ")"), "",
    "Points show occupied equal-width bins. The diagonal denotes ideal agreement. Bin counts are shown by point size.")
  if (!is.null(subgroup_result)) lines <- c(lines, "", "## Subgroup results", "",
    paste0("Grouping variable: ", .md_escape(attr(subgroup_result, "group_variable")), "."), "",
    .md_table(subgroup_result[c("group", "n", "positive_n", "negative_n", "prevalence",
      "roc_auc", "accuracy", "sensitivity", "specificity", "precision", "brier")]), "",
    "NA group labels indicate missing subgroup values. Differences do not establish bias or fairness.")
  if (!is.null(ci_result)) lines <- c(lines, "", "## Bootstrap intervals", "",
    .md_table(ci_result[c("metric", "estimate", "lower", "upper", "conf_level", "n_requested", "n_valid", "n_invalid", "seed")]), "",
    "Percentile intervals use ordinary row resampling and type-7 quantiles. Invalid resamples are excluded separately by metric. A seed of NA means the current RNG was used.")
  lines <- c(lines, "", "## Warnings", "",
    if (length(notes)) paste0("- ", .md_escape(notes)) else "No data-specific warnings were raised.", "",
    "## Scope", "",
    "Use held-out or otherwise appropriate evaluation predictions. The package cannot verify how predictions were generated. Ordinary row bootstrap assumes independent observations and does not include model-retraining or threshold-selection uncertainty. Clustered or repeated patient records need a different resampling design. These results do not establish clinical validity.")
  temp_report <- tempfile("audit-", tmpdir = dirname(report), fileext = ".md")
  temp_figure <- tempfile("calibration-", tmpdir = dirname(report), fileext = ".png")
  on.exit(unlink(c(temp_report, temp_figure)))
  tryCatch({
    writeLines(lines, temp_report, useBytes = TRUE)
    ggplot2::ggsave(temp_figure, plot = plot, width = 6.5, height = 6, dpi = 180, bg = "white")
    if (!file.copy(temp_figure, figure, overwrite = overwrite) ||
        !file.copy(temp_report, report, overwrite = overwrite)) .stop("Could not write report outputs.")
  }, error = function(e) .stop(paste("Report creation failed:", conditionMessage(e))))
  invisible(list(report = report, figure = figure))
}

.check_related_result <- function(x, expected_class, audit, name) {
  if (is.null(x)) return(invisible(NULL))
  if (!inherits(x, expected_class) || !identical(attr(x, "audit_signature"), audit$.signature)) {
    .stop(paste(name, "must be a result for the same audit inputs and settings."))
  }
}

.md_escape <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n]+", " ", x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  for (mark in c("\\", "|", "`", "*", "_", "[", "]")) x <- gsub(mark, paste0("\\", mark), x, fixed = TRUE)
  x
}

.md_table <- function(x) {
  columns <- lapply(x, function(v) {
    if (is.numeric(v)) v <- ifelse(is.na(v), "NA", format(signif(v, 4), trim = TRUE, scientific = FALSE))
    .md_escape(v)
  })
  body <- do.call(cbind, columns)
  c(paste0("| ", paste(.md_escape(names(x)), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
    apply(body, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
}

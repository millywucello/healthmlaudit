# Run from the healthmlaudit repository root.
stopifnot(file.exists("DESCRIPTION"))
required <- c("roxygen2", "testthat", "rcmdcheck", "knitr", "rmarkdown")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install: ", paste(missing, collapse = ", "))
if (!rmarkdown::pandoc_available()) {
  bundled <- "/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64"
  if (file.exists(file.path(bundled, "pandoc"))) {
    Sys.setenv(RSTUDIO_PANDOC = bundled)
    rmarkdown::find_pandoc(cache = FALSE)
  }
}
if (!rmarkdown::pandoc_available()) stop("Pandoc is needed to check the vignette.")
dir.create("docs/validation", recursive = TRUE, showWarnings = FALSE)
roxygen2::roxygenise()
results <- testthat::test_local(reporter = "summary")
results <- as.data.frame(results)
columns <- intersect(c("file", "test", "nb", "failed", "skipped", "error", "warning", "passed"), names(results))
write.csv(results[columns], "docs/validation/test_results.csv", row.names = FALSE)
stopifnot(all(results$failed == 0), !any(results$error), !any(results$skipped), all(results$warning == 0))
check_dir <- tempfile("healthmlaudit-check-")
checked <- rcmdcheck::rcmdcheck(path = ".", args = "--no-manual", build_args = "--no-manual",
  check_dir = check_dir, error_on = "never")
log <- readLines(file.path(check_dir, "healthmlaudit.Rcheck", "00check.log"), warn = FALSE)
writeLines(log, "docs/validation/package_check.txt")
writeLines(trimws(capture.output(sessionInfo()), which = "right"), "docs/validation/session_info.txt")
summary <- c("# Local release validation", "",
  paste("Package version:", read.dcf("DESCRIPTION")[[1,"Version"]]),
  paste("R version:", getRversion()), "",
  paste("Test blocks:", nrow(results)), paste("Passed expectations:", sum(results$passed)),
  paste("Failed expectations:", sum(results$failed)),
  paste("R CMD check:", length(checked$errors), "errors,", length(checked$warnings), "warnings,", length(checked$notes), "notes."), "",
  "The check builds and executes the vignette and examples. PDF manual creation is excluded with --no-manual.", "",
  "Independent numerical checks cover pairwise AUROC, hand-calculated confusion rates and Brier score, and paired-row bootstrap percentiles.", "",
  "CI and fresh GitHub installation are recorded separately in the development log. A successful local check is not a substitute for those results.")
writeLines(summary, "docs/validation/release_summary.md")
stopifnot(!length(checked$errors), !length(checked$warnings), !length(checked$notes))
message("Local release checks passed.")

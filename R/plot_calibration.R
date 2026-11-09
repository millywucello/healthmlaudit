#' Plot binned calibration of predicted probabilities
#'
#' Compare each occupied bin's mean predicted probability with its observed
#' event proportion. Point sizes show the number of observations in the bin.
#'
#' @param audit An object from [audit_binary()].
#' @param bins An integer from 1 to 1000 giving the number of equal-width bins.
#' @param method Binning method. Currently only `"equal_width"` is supported.
#' @return An editable ggplot object. Its `data` contains `bin`, `lower`, `upper`,
#'   `n`, `events`, `mean_predicted`, and `observed_rate`. Attribute
#'   `audit_warnings` contains messages about small samples; `empty_bins` counts
#'   unoccupied intervals.
#' @details Intervals include their lower endpoint and exclude their upper
#'   endpoint, except the last interval, which includes 1. Empty bins are omitted.
#'   Samples smaller than 30, or smaller than the requested number of bins,
#'   produce a warning. These are descriptive flags, not validated sample-size
#'   criteria. The diagonal denotes equality of mean prediction and event rate.
#'   This plot is not a calibration test or evidence of clinical validity.
#' @examples
#' audit <- audit_binary(demo_predictions, "outcome", "predicted_risk")
#' plot_calibration(audit, bins = 8)
#' @importFrom rlang .data
#' @export
plot_calibration <- function(audit, bins = 10, method = "equal_width") {
  .check_audit(audit)
  .check_number(bins, "bins", 1, 1000, integer = TRUE)
  if (!identical(method, "equal_width")) .stop('method must be "equal_width".')
  probability <- audit$.probability
  outcome <- audit$.outcome
  bin <- pmin(floor(probability * bins) + 1L, bins)
  occupied <- sort(unique(bin))
  tab <- do.call(rbind, lapply(occupied, function(i) {
    rows <- which(bin == i)
    data.frame(bin = i, lower = (i - 1) / bins, upper = i / bins,
      n = length(rows), events = sum(outcome[rows]),
      mean_predicted = mean(probability[rows]), observed_rate = mean(outcome[rows]))
  }))
  messages <- character()
  if (length(outcome) < 30L) messages <- c(messages, "Fewer than 30 observations: calibration bin rates may be unstable.")
  if (length(outcome) < bins) messages <- c(messages, "Fewer observations than requested bins; consider fewer bins.")
  plot <- ggplot2::ggplot(tab, ggplot2::aes(x = .data$mean_predicted, y = .data$observed_rate)) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "#777777") +
    ggplot2::geom_point(ggplot2::aes(size = .data$n), colour = "#196B86", alpha = .85) +
    ggplot2::scale_size_continuous(range = c(3, 8)) +
    ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, .25), expand = ggplot2::expansion(add = .035)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .25), expand = ggplot2::expansion(add = .035)) +
    ggplot2::coord_equal() +
    ggplot2::labs(title = "Calibration of binary predictions",
      subtitle = paste0("Positive class: ", audit$metadata$positive, " | n = ", length(outcome),
                        " | ", nrow(tab), " of ", bins, " bins occupied"),
      x = "Mean predicted event probability", y = "Observed event proportion",
      size = "Bin count", caption = "Dashed line: ideal agreement. Binned summaries are descriptive.") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), legend.position = "bottom")
  attr(plot, "audit_warnings") <- messages
  attr(plot, "empty_bins") <- bins - nrow(tab)
  .signal_warnings(messages)
  plot
}

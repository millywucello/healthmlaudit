#' Synthetic binary outcomes and predicted risks
#'
#' Four hundred independently simulated observations for demonstrating the
#' audit workflow. Identifiers are fictional. No private patient data are used.
#'
#' @format A data frame with 400 rows and four columns:
#' \describe{
#'   \item{patient_id}{Fictional identifier from S001 through S400.}
#'   \item{outcome}{Simulated event indicator, 0 or 1.}
#'   \item{predicted_risk}{Probability assigned to outcome 1.}
#'   \item{age_group}{Synthetic group label: Under 60 or 60+. Each has 200 rows.}
#' }
#' @details Outcomes are Bernoulli draws from logistic probabilities. The
#'   predictions use a modified score with a group-dependent shift to illustrate
#'   calibration differences. No model is trained on these observations.
#'   The generation script uses seed 5233 and is included in `data-raw/` in the
#'   source repository. This example does not describe a clinical population.
#' @source Generated for this package with base R; see `data-raw/generate_demo_data.R`.
#' @examples
#' dim(demo_predictions)
#' audit_binary(demo_predictions, "outcome", "predicted_risk")$metrics
"demo_predictions"

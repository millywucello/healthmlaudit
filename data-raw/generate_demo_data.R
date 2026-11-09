# Run from the package root. No external data or fitted model is used.
set.seed(5233)
n <- 400L
age_group <- rep(c("Under 60", "60+"), each = n / 2L)
latent_score <- rnorm(n, mean = ifelse(age_group == "60+", .25, -.35), sd = 1.1)
true_probability <- plogis(-.45 + latent_score)
outcome <- rbinom(n, 1, true_probability)
# Add a group-dependent shift to make calibration differences visible.
predicted_risk <- plogis(-.45 + 1.15 * latent_score + ifelse(age_group == "60+", .65, -.1))
demo_predictions <- data.frame(patient_id = sprintf("S%03d", seq_len(n)),
  outcome = outcome, predicted_risk = predicted_risk,
  age_group = factor(age_group, levels = c("Under 60", "60+")))
save(demo_predictions, file = "data/demo_predictions.rda", compress = "xz", version = 2)

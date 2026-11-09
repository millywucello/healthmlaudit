test_that("metrics agree with the hand-calculated four-row example", {
  d <- small_predictions()
  a <- audit_binary(d, "outcome", "predicted_risk")
  expect_s3_class(a, "healthmlaudit")
  expect_equal(a$metrics$roc_auc, 1)
  expect_equal(a$metrics$accuracy, .75)
  expect_equal(a$metrics$sensitivity, 1)
  expect_equal(a$metrics$specificity, .5)
  expect_equal(a$metrics$precision, 2/3)
  expect_equal(a$metrics$brier, .125)
  expect_equal(unlist(a$metrics[c("tp", "fp", "tn", "fn")]), c(tp=2,fp=1,tn=1,fn=0))
  expect_identical(a$data, d)
  expect_equal(a$metadata$n_omitted, 0)
  expect_identical(a$warnings, character())
})

test_that("positive class is explicit and independent of factor order", {
  d <- small_predictions()
  d$outcome <- factor(ifelse(d$outcome == 1, "yes", "no"), levels = c("no", "yes"))
  a <- audit_binary(d, "outcome", "predicted_risk", positive = "yes")
  expect_equal(a$metrics$roc_auc, 1)
  expect_equal(a$metrics$brier, .125)
  d$outcome <- factor(d$outcome, levels = c("yes", "no"))
  expect_equal(a$metrics, audit_binary(d, "outcome", "predicted_risk", positive="yes")$metrics)
})

test_that("probabilities of the opposite positive class give consistent metrics", {
  d <- small_predictions()
  d$predicted_risk <- 1 - d$predicted_risk
  a <- audit_binary(d, "outcome", "predicted_risk", positive = 0)
  expect_equal(a$metrics$roc_auc, 1)
  expect_equal(a$metrics$brier, .125)
  expect_equal(a$metrics$sensitivity, .5)
  expect_equal(a$metrics$specificity, 1)
})

test_that("AUROC handles ties and reversed rankings", {
  d <- data.frame(y=c(1,0),p=c(.5,.5))
  expect_equal(audit_binary(d,"y","p")$metrics$roc_auc,.5)
  d$p <- c(.1,.9)
  expect_equal(audit_binary(d,"y","p")$metrics$roc_auc,0)
})

test_that("threshold equality is classified as positive", {
  d <- data.frame(y=c(1,0),p=c(.5,.49))
  a <- audit_binary(d,"y","p")
  expect_equal(a$metrics$accuracy,1)
  expect_equal(a$metrics$tp,1)
  expect_equal(audit_binary(d,"y","p",threshold=0)$metrics$accuracy,.5)
  expect_warning(a1 <- audit_binary(d,"y","p",threshold=1), "Precision")
  expect_equal(a1$metrics$tn,1)
})

test_that("single-class and no-positive-prediction metrics are explicit", {
  d <- data.frame(y=c(0,0),p=c(.1,.2))
  expect_warning(a <- audit_binary(d,"y","p"),"AUROC")
  expect_true(is.na(a$metrics$roc_auc))
  expect_true(is.na(a$metrics$sensitivity))
  expect_true(is.na(a$metrics$precision))
  expect_equal(a$metrics$specificity,1)
  expect_equal(a$metrics$brier,.025)
  d$y <- c(1,1)
  expect_warning(b <- audit_binary(d,"y","p"),"Specificity")
  expect_equal(b$metrics$sensitivity,0)
  expect_true(is.na(b$metrics$specificity))
})

test_that("print returns the audit invisibly", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  expect_output(result <- print(a),"Positive class")
  expect_identical(result,a)
})

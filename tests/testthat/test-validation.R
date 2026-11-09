test_that("invalid data and missing columns have useful errors", {
  d <- small_predictions()
  expect_error(audit_binary(as.matrix(d),"outcome","predicted_risk"),"data frame")
  expect_error(audit_binary(d[FALSE,],"outcome","predicted_risk"),"non-empty")
  expect_error(audit_binary(d,"absent","predicted_risk"),"absent")
  expect_error(audit_binary(d,"outcome","outcome"),"different")
  names(d)[3] <- "outcome"
  expect_error(audit_binary(d,"outcome","predicted_risk"),"unique")
})

test_that("invalid probabilities are rejected, even when their truth is missing", {
  for (value in list(-.1,1.01,Inf,-Inf)) {
    d <- small_predictions();d$predicted_risk[1] <- value;d$outcome[1] <- NA
    expect_error(audit_binary(d,"outcome","predicted_risk",na_action="omit"),"prob")
  }
  d <- small_predictions();d$predicted_risk <- as.character(d$predicted_risk)
  expect_error(audit_binary(d,"outcome","predicted_risk"),"numeric")
})

test_that("missingness is reported without dropping unrelated missing columns", {
  d <- small_predictions();d$outcome[1] <- NA;d$age_group[2] <- NA
  expect_error(audit_binary(d,"outcome","predicted_risk"),"missing")
  expect_warning(a <- audit_binary(d,"outcome","predicted_risk",na_action="omit"),"1 rows")
  expect_equal(a$metadata$omitted_rows,1L)
  expect_equal(a$metadata$n_input,4L)
  expect_equal(a$metadata$n_used,3L)
  expect_true(is.na(a$data$age_group[1]))
  d$outcome[] <- NA
  expect_error(audit_binary(d,"outcome","predicted_risk",na_action="omit"),"No observations")
})

test_that("threshold, class, and missingness settings are validated", {
  d <- small_predictions()
  for (x in list(-1,1.1,NA_real_,Inf,c(.2,.3),"0.5"))
    expect_error(audit_binary(d,"outcome","predicted_risk",threshold=x),"threshold")
  for (x in list(NA,character(),c(0,1),""))
    expect_error(audit_binary(d,"outcome","predicted_risk",positive=x),"positive")
  expect_error(audit_binary(d,"outcome","predicted_risk",positive="typo"),"binary")
  expect_error(audit_binary(d,"outcome","predicted_risk",na_action="drop"),"na_action")
  d$outcome <- c(1,2,3,4)
  expect_error(audit_binary(d,"outcome","predicted_risk"),"binary")
})

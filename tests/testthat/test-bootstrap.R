test_that("bootstrap reproduces an independent paired-row Brier calculation", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  set.seed(99)
  expected <- replicate(80, {
    i <- sample.int(4,4,replace=TRUE)
    mean((a$data$outcome[i]-a$data$predicted_risk[i])^2)
  })
  b <- bootstrap_ci(a,metrics="brier",times=80,seed=99)
  expect_equal(b$estimate,.125)
  expect_equal(attr(b,"replicates")[,"brier"],expected)
  expect_equal(c(b$lower,b$upper),as.numeric(quantile(expected,c(.025,.975))))
  expect_equal(b$n_valid,80)
  expect_equal(b$n_invalid,0)
})

test_that("seeded runs are identical and preserve the caller's RNG", {
  a <- audit_binary(demo_predictions,"outcome","predicted_risk")
  set.seed(17);before <- .Random.seed
  x <- bootstrap_ci(a,times=40,seed=42)
  expect_identical(.Random.seed,before)
  expect_identical(x,bootstrap_ci(a,times=40,seed=42))
  expect_false(identical(attr(x,"replicates"),attr(bootstrap_ci(a,times=40,seed=43),"replicates")))
  bootstrap_ci(a,times=10,seed=NULL)
  expect_false(identical(.Random.seed,before))
})

test_that("undefined AUROC resamples are counted separately from Brier", {
  a <- audit_binary(data.frame(y=c(0,1),p=c(.2,.8)),"y","p")
  expect_warning(b <- bootstrap_ci(a,times=100,seed=7),"undefined")
  expect_true(b$n_invalid[b$metric=="roc_auc"]>0)
  expect_equal(b$n_invalid[b$metric=="brier"],0)
  expect_true(all(b$n_valid+b$n_invalid==100))
  expect_equal(b$n_valid[b$metric=="roc_auc"],sum(is.finite(attr(b,"replicates")[,"roc_auc"])))
  one <- suppressWarnings(audit_binary(data.frame(y=c(0,0),p=c(.1,.2)),"y","p"))
  expect_warning(z <- bootstrap_ci(one,metrics="roc_auc",times=10),"Fewer than two")
  expect_true(is.na(z$lower) && is.na(z$upper) && is.na(z$estimate))
  expect_equal(z$n_valid,0)
})

test_that("bootstrap arguments are validated", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  for (x in list(1,0,1.1,NA_real_,Inf,"20")) expect_error(bootstrap_ci(a,times=x),"times")
  for (x in list(0,1,-.5,NA_real_,Inf)) expect_error(bootstrap_ci(a,conf_level=x),"conf_level")
  for (x in list(character(),"auroc",c("brier","brier"),NA_character_)) expect_error(bootstrap_ci(a,metrics=x),"metrics")
  for (x in list(-1,1.1,NA_real_,Inf)) expect_error(bootstrap_ci(a,seed=x),"seed")
})

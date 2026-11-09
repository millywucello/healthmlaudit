test_that("all metrics agree with independent calculations on tied scores", {
  d <- data.frame(y=c(1,0,1,0,0,1,0,1,0,1),p=c(.9,.9,.8,.6,.4,.4,.3,.2,.1,0))
  for (threshold in c(0,.25,.4,.5,.9,1)) {
    a <- suppressWarnings(audit_binary(d,"y","p",threshold=threshold))
    pred <- as.integer(d$p>=threshold)
    pos <- d$p[d$y==1];neg <- d$p[d$y==0]
    pairs <- outer(pos,neg,function(p,n) (p>n)+.5*(p==n))
    expect_equal(a$metrics$roc_auc,mean(pairs))
    expect_equal(a$metrics$accuracy,mean(pred==d$y))
    expect_equal(a$metrics$sensitivity,mean(pred[d$y==1]==1))
    expect_equal(a$metrics$specificity,mean(pred[d$y==0]==0))
    expected_ppv <- if (sum(pred)>0) mean(d$y[pred==1]) else NA_real_
    expect_equal(a$metrics$precision,expected_ppv)
    expect_equal(a$metrics$brier,mean((d$y-d$p)^2))
  }
})

test_that("row order and factor labels do not change performance", {
  d <- small_predictions()
  a <- audit_binary(d,"outcome","predicted_risk")
  expect_equal(a$metrics,audit_binary(d[4:1,],"outcome","predicted_risk")$metrics)
  d$outcome <- as.logical(d$outcome)
  expect_equal(a$metrics,audit_binary(d,"outcome","predicted_risk",positive=TRUE)$metrics)
})

test_that("complex inputs and modified results fail clearly", {
  d <- small_predictions()
  expect_error(audit_binary(d,"outcome","predicted_risk",threshold=.5+1i),"threshold")
  expect_error(audit_binary(d,"outcome","predicted_risk",positive=1+1i),"positive")
  d$predicted_risk <- as.complex(d$predicted_risk)
  expect_error(audit_binary(d,"outcome","predicted_risk"),"numeric")
  d <- small_predictions();d$outcome <- as.complex(d$outcome)
  expect_error(audit_binary(d,"outcome","predicted_risk"),"binary labels")
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  a$metrics$accuracy <- 100
  expect_error(bootstrap_ci(a),"changed")
})

test_that("a supplied seed also preserves the absence of an RNG state", {
  had <- exists(".Random.seed",envir=globalenv(),inherits=FALSE)
  if (had) old <- get(".Random.seed",envir=globalenv())
  on.exit(if (had) assign(".Random.seed",old,envir=globalenv()))
  if (had) rm(".Random.seed",envir=globalenv())
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  bootstrap_ci(a,metrics="brier",times=20,seed=4)
  expect_false(exists(".Random.seed",envir=globalenv(),inherits=FALSE))
})

test_that("every supported metric is available to bootstrap", {
  a <- audit_binary(demo_predictions,"outcome","predicted_risk")
  metrics <- c("roc_auc","accuracy","sensitivity","specificity","precision","brier")
  ci <- bootstrap_ci(a,metrics=metrics,times=20)
  expect_identical(ci$metric,metrics)
  expect_true(all(ci$n_valid==20))
  expect_true(all(ci$lower<=ci$upper))
  expect_true(all(ci$estimate>=0 & ci$estimate<=1))
})

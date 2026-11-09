test_that("calibration bin summaries match hand calculations", {
  d <- data.frame(y=c(0,1,0,1),p=c(0,.5,.5,1))
  a <- audit_binary(d,"y","p")
  expect_warning(p <- plot_calibration(a,bins=2),"Fewer than 30")
  expect_s3_class(p,"ggplot")
  expect_equal(p$data$n,c(1L,3L))
  expect_equal(p$data$mean_predicted,c(0,2/3))
  expect_equal(p$data$observed_rate,c(0,2/3))
  expect_equal(sum(p$data$n),4)
  expect_equal(sum(p$data$events),2)
})

test_that("empty bins and exact endpoints are handled without invented data", {
  a <- audit_binary(data.frame(y=rep(c(0,1),20),p=rep(c(0,1),20)),"y","p")
  p <- plot_calibration(a,bins=10)
  expect_equal(p$data$bin,c(1,10))
  expect_equal(attr(p,"empty_bins"),8)
  expect_equal(p$data$observed_rate,c(0,1))
  expect_equal(p$data$n,c(20,20))
  expect_equal(nrow(plot_calibration(a,bins=1)$data),1)
})

test_that("calibration parameters and audit objects are checked", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  for (b in list(0,-1,2.5,NA_real_,Inf,1001,"10")) expect_error(plot_calibration(a,bins=b),"bins")
  expect_error(plot_calibration(a,method="quantile"),"method")
  expect_error(plot_calibration(list()),"audit_binary")
  a$data$predicted_risk[1] <- .1
  expect_error(plot_calibration(a),"changed")
})

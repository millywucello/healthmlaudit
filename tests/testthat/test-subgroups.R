test_that("subgroups reuse settings and account for every retained observation", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk",threshold=.8)
  expect_warning(g <- audit_subgroups(a,"age_group"),"Subgroup issues")
  expect_equal(g$n,c(2,2))
  expect_equal(g$prevalence,c(.5,.5))
  expect_equal(g$accuracy,c(1,.5))
  expect_equal(g$brier,c(.025,.225))
  expect_equal(g$threshold,c(.8,.8))
  expect_equal(sum(g$n),a$metadata$n_used)
  expect_equal(g$sensitivity,c(1,0))
})

test_that("single-class groups report undefined rates and missing labels stay separate", {
  d <- data.frame(y=c(0,0,1,1),p=c(.1,.2,.8,.9),g=c("A","A",NA,"(Missing)"))
  a <- audit_binary(d,"y","p")
  expect_warning(g <- audit_subgroups(a,"g",min_n=1),"Subgroup issues")
  expect_equal(nrow(g),3)
  expect_equal(sum(g$is_missing_group),1)
  expect_true(all(is.na(g$roc_auc)))
  expect_equal(g$negative_n[1],2)
  expect_true(is.na(g$sensitivity[1]))
  expect_match(g$warnings[g$is_missing_group],"Missing subgroup")
  expect_equal(sum(g$n),4)
})

test_that("unused groups are omitted and optional missingness is not discarded", {
  d <- small_predictions();d$age_group <- factor(c("A","B",NA,"B"),levels=c("A","B","unused"))
  a <- audit_binary(d,"outcome","predicted_risk")
  expect_warning(g <- audit_subgroups(a,"age_group",min_n=1),"Subgroup issues")
  expect_false("unused" %in% g$group)
  expect_equal(sum(g$n),4)
})

test_that("subgroup arguments are validated", {
  a <- audit_binary(small_predictions(),"outcome","predicted_risk")
  expect_error(audit_subgroups(a,"absent"),"Missing group")
  for (n in list(0,-1,2.2,NA,"30")) expect_error(audit_subgroups(a,"age_group",min_n=n),"min_n")
})

# Rscript truth-recovery/test-truth-recovery.R
# Fast measured invariants for the BAP-MR truth-recovery yardstick. Seeded; no
# hand-entered numbers. (Light nsim/B so it runs in ~1 min; the full grid is in
# harness.R / REPORT.md.)

.libPaths(c("C:/Users/mahmo/Rlibs", .libPaths()))
suppressMessages({ library(glmnet); library(metafor) })
this <- sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)[1])
source(file.path(dirname(this), "..", "R", "bapmr.R"))
source(file.path(dirname(this), "dgp-helpers.R"))

set.seed(20260613)
NSIM <- 30; B <- 20
beta_true <- c(0.40, 0, 0, 0)

measure <- function(k, tau2) {
  modIdx <- 2:5
  mB <- mL <- c(); fpB <- c()
  for (s in 1:NSIM) {
    d <- gen(k, 4, beta_true, tau2, seed = 1000 + s)
    cb <- tryCatch(bapmr(d$y, d$v, d$X, B = B, alpha = 1, seed = 7 + s)$coefficients,
                   error = function(e) rep(NA, 5))
    cl <- fit_single_lasso(d$y, d$v, d$X)
    if (!any(is.na(cb))) { mB <- c(mB, mean((cb[modIdx] - beta_true)^2))
                           fpB <- c(fpB, mean(abs(cb[modIdx][beta_true == 0]) > 1e-6)) }
    if (!any(is.na(cl))) mL <- c(mL, mean((cl[modIdx] - beta_true)^2))
  }
  list(mseBap = mean(mB), mseLas = mean(mL), fpBap = mean(fpB))
}

ok <- TRUE
report <- function(name, cond, detail) {
  cat(sprintf("%-4s %s  %s\n", if (cond) "PASS" else "FAIL", name, detail))
  if (!cond) ok <<- FALSE
}

r8 <- measure(8, 0.05)
report("bapmr-beats-single-lasso-at-small-k",
       r8$mseBap < r8$mseLas,
       sprintf("(k=8: MSE BAP-MR %.4f < single-LASSO %.4f)", r8$mseBap, r8$mseLas))
report("bagging-destroys-selection-(FP-near-1)",
       r8$fpBap > 0.8,
       sprintf("(k=8: BAP-MR noise-moderator false-positive rate %.3f -- bagged coefs almost never zero)", r8$fpBap))

if (!ok) quit(status = 1)
cat("\nAll measured invariants hold.\n")

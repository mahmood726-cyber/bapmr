# ============================================================
# harness.R -- Truth-recovery yardstick for BAP-MR (bapmr).
#
# BAP-MR claims to "resolve the regularization paradox where LASSO increases
# overfitting in small meta-regressions" by averaging penalized coefficients
# across bootstrap resamples. That is a claim about ESTIMATOR ACCURACY/STABILITY
# under a KNOWN truth -- exactly what a known-truth simulation can adjudicate.
#
# This harness injects a known SPARSE meta-regression truth (one real moderator
# among several noise moderators, with residual heterogeneity) and compares, on
# coefficient MSE vs the truth and on selection behaviour:
#   - BAP-MR            (the shipped bagged elastic-net, R/bapmr.R)
#   - single CV-LASSO   (cv.glmnet lambda.1se -- the comparator it claims to beat)
#   - unpenalised WLS   (metafor::rma moderator model -- no shrinkage baseline)
#
# Truth-first: every number is produced from seeded simulation here. Nothing is
# hand-entered. Run:  Rscript truth-recovery/harness.R
# ============================================================

.libPaths(c("C:/Users/mahmo/Rlibs", .libPaths()))
suppressMessages({ library(glmnet); library(metafor) })
source(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)[1])), "..", "R", "bapmr.R"))

set.seed(20260613)

source(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)[1])), "dgp-helpers.R"))

run_cell <- function(k, p, beta_true, tau2, nsim, B) {
  modIdx <- 2:(p + 1)                                # coefficient slots for moderators
  acc <- list(BAPMR = c(), LASSO = c(), WLS = c())
  selBap <- selLas <- matrix(0, nrow = 0, ncol = p)
  for (s in 1:nsim) {
    d <- gen(k, p, beta_true, tau2, seed = 1000 + s)
    cb <- tryCatch(bapmr(d$y, d$v, d$X, B = B, alpha = 1, seed = 7 + s)$coefficients,
                   error = function(e) rep(NA, p + 1))
    cl <- fit_single_lasso(d$y, d$v, d$X)
    cw <- fit_wls(d$y, d$v, d$X)
    bt <- c(0.10, beta_true)
    mse <- function(co) if (any(is.na(co))) NA else mean((co[modIdx] - beta_true)^2)
    acc$BAPMR <- c(acc$BAPMR, mse(cb)); acc$LASSO <- c(acc$LASSO, mse(cl)); acc$WLS <- c(acc$WLS, mse(cw))
    if (!any(is.na(cb))) selBap <- rbind(selBap, abs(cb[modIdx]) > 1e-6)
    if (!any(is.na(cl))) selLas <- rbind(selLas, abs(cl[modIdx]) > 1e-6)
  }
  list(
    k = k, tau2 = tau2,
    mse = sapply(acc, function(z) round(mean(z, na.rm = TRUE), 5)),
    # false-positive rate on the NOISE moderators (true zero) for the two penalised methods
    fpBap = round(mean(selBap[, beta_true == 0, drop = FALSE]), 4),
    fpLas = round(mean(selLas[, beta_true == 0, drop = FALSE]), 4),
    # detection rate of the real signal (true nonzero)
    tpBap = round(mean(selBap[, beta_true != 0, drop = FALSE]), 4),
    tpLas = round(mean(selLas[, beta_true != 0, drop = FALSE]), 4)
  )
}

args <- commandArgs(TRUE)
NSIM <- if (length(args) >= 1) as.integer(args[1]) else 80
B    <- if (length(args) >= 2) as.integer(args[2]) else 40

cat(sprintf("\n# Truth-recovery yardstick -- BAP-MR  (nsim=%d, B=%d, seed=20260613)\n", NSIM, B))
cat("True sparse meta-regression: intercept 0.10, moderators beta=(0.40, 0, 0, 0)\n")
cat("(one real signal + three noise moderators -- the small-k overfitting regime)\n\n")
beta_true <- c(0.40, 0, 0, 0)
cells <- list(c(8, 0.01), c(8, 0.05), c(15, 0.01), c(15, 0.05), c(25, 0.05))
cat(sprintf("%4s %6s | %10s %10s %10s | %7s %7s | %7s %7s\n",
            "k", "tau2", "MSE.BAPMR", "MSE.LASSO", "MSE.WLS", "FP.Bap", "FP.Las", "TP.Bap", "TP.Las"))
res <- list()
for (cl in cells) {
  r <- run_cell(cl[1], 4, beta_true, cl[2], NSIM, B)
  res[[length(res) + 1]] <- r
  cat(sprintf("%4d %6.2f | %10.5f %10.5f %10.5f | %7.3f %7.3f | %7.3f %7.3f\n",
              r$k, r$tau2, r$mse["BAPMR"], r$mse["LASSO"], r$mse["WLS"],
              r$fpBap, r$fpLas, r$tpBap, r$tpLas))
}
saveRDS(res, file.path("truth-recovery", "results.rds"))
cat("\n(MSE = mean squared error of moderator coefficients vs truth; lower is better.\n")
cat(" FP = fraction of NOISE moderators selected nonzero; TP = signal detection rate.)\n")

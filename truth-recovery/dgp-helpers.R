# dgp-helpers.R -- known-truth DGP + comparator fitters for the BAP-MR yardstick.
# Sourced by both harness.R and test-truth-recovery.R. Standalone (needs glmnet,
# metafor on the lib path). Seeded -> reproducible.

# known-truth DGP: k studies, p moderators, sparse truth + residual heterogeneity.
gen <- function(k, p, beta_true, tau2, seed) {
  set.seed(seed)
  X <- matrix(rnorm(k * p), nrow = k, ncol = p)
  mu <- 0.10 + X %*% beta_true                       # intercept 0.10
  theta <- mu + rnorm(k, 0, sqrt(tau2))              # residual heterogeneity
  v <- runif(k, 0.02, 0.20)                          # sampling variances
  y <- theta + rnorm(k, 0, sqrt(v))
  list(y = as.vector(y), v = v, X = X, beta_true = beta_true)
}

fit_single_lasso <- function(y, v, X) {
  cv <- tryCatch(glmnet::cv.glmnet(X, y, weights = 1 / v, alpha = 1,
                                   nfolds = min(5, length(y)), grouped = FALSE),
                 error = function(e) NULL)
  if (is.null(cv)) return(rep(NA, ncol(X) + 1))
  as.vector(coef(cv, s = "lambda.1se"))
}

fit_wls <- function(y, v, X) {
  m <- tryCatch(metafor::rma(yi = y, vi = v, mods = X, method = "REML"),
                error = function(e) tryCatch(metafor::rma(yi = y, vi = v, mods = X, method = "DL"),
                                             error = function(e2) NULL))
  if (is.null(m)) return(rep(NA, ncol(X) + 1))
  as.vector(m$beta)
}

# Truth-recovery yardstick — bapmr (BAP-MR)

**Verdict: VALIDATION of the core claim + two honest boundaries. BAP-MR genuinely
beats single CV-LASSO on coefficient MSE in small meta-regressions; but its edge
over unpenalised WLS is confined to small k, and bagging destroys variable
selection.**

## Method
BAP-MR claims to "resolve the regularization paradox where LASSO increases
overfitting in small meta-regressions" by averaging penalized coefficients across
bootstrap resamples. That is a claim about **estimator accuracy under a known
truth** — adjudicable by simulation. The harness injects a known **sparse**
meta-regression truth (intercept 0.10; moderators β = (0.40, 0, 0, 0) — one real
signal among three noise moderators, the small-k overfitting regime) with residual
heterogeneity, and compares on coefficient MSE-vs-truth and on selection:
- **BAP-MR** — the shipped bagged elastic-net (`R/bapmr.R`, run unchanged).
- **single CV-LASSO** — `cv.glmnet` `lambda.1se` (the comparator it claims to beat).
- **unpenalised WLS** — `metafor::rma` moderator model (no-shrinkage baseline).

60 sims/cell, B=30 bootstraps, seed 20260613.

## Results

| k  | τ²   | MSE BAP-MR | MSE LASSO | MSE WLS | FP BAP-MR | FP LASSO | TP BAP-MR | TP LASSO |
|---:|-----:|-----------:|----------:|--------:|----------:|---------:|----------:|---------:|
| 8  | 0.01 | **0.0198** | 0.0322 | 0.0501 | 0.967 | 0.206 | 1.000 | 0.550 |
| 8  | 0.05 | **0.0213** | 0.0321 | 0.0665 | 0.983 | 0.189 | 1.000 | 0.550 |
| 15 | 0.01 | 0.0109 | 0.0133 | **0.0101** | 0.989 | 0.106 | 1.000 | 0.900 |
| 15 | 0.05 | 0.0144 | 0.0181 | **0.0134** | 1.000 | 0.133 | 1.000 | 0.800 |
| 25 | 0.05 | 0.0093 | 0.0123 | **0.0067** | 0.939 | 0.050 | 1.000 | 0.900 |

(MSE = mean squared error of moderator coefficients vs truth; FP = fraction of the
3 NOISE moderators selected nonzero; TP = detection rate of the real signal.)

## Findings (all measured)
1. **VALIDATION — the headline claim holds.** BAP-MR has lower coefficient MSE than
   single CV-LASSO at **every** k tested. The advantage is largest exactly where
   the claim is aimed — small k: at k=8 MSE 0.020 vs 0.032 (~39% lower). The
   bagging genuinely stabilises the unstable single-shot LASSO. The
   regularization-paradox mitigation is real.
2. **Honest boundary #1 — only beats *unpenalised WLS* at small k.** At k=8 BAP-MR
   crushes WLS (0.020 vs 0.050–0.067). But by k=15 WLS draws level (0.0101 vs
   0.0109) and by k=25 WLS clearly wins (0.0067 vs 0.0093): with enough data,
   shrinkage over-shrinks the true signal. → **BAP-MR is a small-k tool (k ≲ 15);
   it should not be recommended as a universal default over WLS.**
3. **Honest boundary #2 — bagging destroys variable selection.** BAP-MR's *bagged*
   coefficients are almost never exactly zero (noise-moderator false-positive rate
   0.94–1.00), because averaging across bootstrap resamples washes out LASSO's
   sparsity. Single LASSO keeps selection (FP 0.05–0.21). → **BAP-MR is a
   shrinkage/prediction estimator, NOT a moderator-selection tool.** Any README/UI
   copy implying it identifies "which moderators matter" should be corrected; for
   selection, single LASSO is the right tool. (It does have perfect signal
   detection — TP 1.00 — but at the cost of never zeroing noise.)

## Recommendation
- Keep BAP-MR as the small-k shrinkage estimator it is; document the k ≲ 15
  applicability and that it does not perform selection. Consider reporting the
  bootstrap inclusion frequency per moderator (fraction of B fits with nonzero
  coefficient) as an honest selection signal, instead of the bagged point estimate.

## What did NOT transfer
NPE/conformal/SBC/PartialID are estimator-of-μ-coverage machinery; BAP-MR is a
penalised point estimator, so the fitting part of the recipe (known-truth bias/MSE
+ selection accuracy) transferred, not the coverage/calibration part. The shipped
R engine is run unchanged; only glmnet/metafor (its declared deps) are required.

## Reproduce
```
Rscript truth-recovery/harness.R 60 30        # full grid (~3 min)
Rscript truth-recovery/test-truth-recovery.R  # fast measured invariants (~1 min)
```

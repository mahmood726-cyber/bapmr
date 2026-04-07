Mahmood Ahmad
Tahir Heart Institute
mahmood.ahmad2@nhs.net

Bootstrap-Aggregated Penalized Meta-Regression for Small-Sample Evidence Synthesis

Can bootstrap aggregation resolve the regularization paradox whereby LASSO increases overfitting in small-sample meta-regression settings? We developed BAP-MR using five benchmark datasets from the metadat R package including BCG vaccination, Berkey periodontal, and Konstantopoulos multi-site trials with study counts from ten to forty-one. The method applies LASSO across bootstrap resamples of the meta-analytic dataset and averages the resulting penalized coefficients and heterogeneity estimates to stabilize lambda selection. In null simulations with ten studies and two moderators, standard LASSO produced 30.6 percent mean optimism while BAP-MR suppressed optimism to 8.2 percent, outperforming unpenalized restricted maximum likelihood at 13.0 percent. Across all five empirical datasets, BAP-MR consistently delivered the most conservative R-squared-het estimates and resisted spurious moderator discovery plaguing single-pass penalization. Bagging the penalization process provides a principled solution to unstable cross-validation in small-sample evidence synthesis. The limitation of bootstrap resampling is that performance may degrade with extremely small study counts below eight where resamples become insufficiently diverse.

Outside Notes

Type: methods
Primary estimand: R-squared heterogeneity
App: bapmr R package v0.1.0
Data: BCG, Berkey, Hackshaw, Konstantopoulos, Teacher datasets from metadat
Code: https://github.com/mahmood726-cyber/bapmr
Version: 0.1.0
Validation: DRAFT

References

1. Thompson SG, Higgins JPT. How should meta-regression analyses be undertaken and interpreted? Stat Med. 2002;21(11):1559-1573.
2. Viechtbauer W. Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1-48.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.

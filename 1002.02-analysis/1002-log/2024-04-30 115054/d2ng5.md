# D2NG5

```
> library(nnet)
> modelSnapMorCrude <- multinom(hospMortality ~ group, data = snapGroupMorCrud$
# weights:  6 (5 variable)
initial  value 6661.144405
final  value 5435.500442 
converged
> summary(modelSnapMorCrude)
Call:
multinom(formula = hospMortality ~ group, data = snapGroupMorCrude)

Coefficients:
                 Values  Std. Err.
(Intercept) -1.22720369 0.04953455
group2       0.82173210 0.06515972
group3      -0.23917020 0.07141812
group4       1.51485736 0.10891389
group5       0.08778702 0.07151880

Residual Deviance: 10871
AIC: 10881
> # z value
> zSnapMorCrude <- summary(modelSnapMorCrude)$coefficients / summary(modelSnap$
> # 2-tailed z test
> pSnapMorCrude <- (1 - pnorm(abs(zSnapMorCrude), 0, 1)) * 2
> pSnapMorCrude
 (Intercept)       group2       group3       group4       group5
0.0000000000 0.0000000000 0.0008114109 0.0000000000 0.2196468030
> # or value
> orSnapMorCrude <- exp(coef(modelSnapMorCrude))
> orSnapMorCrude
(Intercept)      group2      group3      group4      group5
  0.2931111   2.2744360   0.7872809   4.5487722   1.0917556
> # 95% ci
> ciSnapMorCrude <- exp(confint(modelSnapMorCrude))
> ciSnapMorCrude
                2.5 %    97.5 %
(Intercept) 0.2659918 0.3229952
group2      2.0017492 2.5842693
group3      0.6844449 0.9055677
group4      3.6744007 5.6312118
group5      0.9489613 1.2560367
```


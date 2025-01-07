# D2NG4

```
> library(nnet)
> modelSnapMorCrude <- multinom(hospMortality ~ group, data = snapGroupMorCrud$
# weights:  5 (4 variable)
initial  value 6661.144405 
final  value 5467.280435 
converged
> summary(modelSnapMorCrude)
Call:
multinom(formula = hospMortality ~ group, data = snapGroupMorCrude)

Coefficients:
                Values  Std. Err.
(Intercept) -1.5260558 0.05116683
group2       0.6456965 0.06293014
group3       1.6595878 0.08329659
group4       0.4930410 0.06856304

Residual Deviance: 10934.56
AIC: 10942.56
> # z value
> zSnapMorCrude <- summary(modelSnapMorCrude)$coefficients / summary(modelSnap$
> # 2-tailed z test
> pSnapMorCrude <- (1 - pnorm(abs(zSnapMorCrude), 0, 1)) * 2
> pSnapMorCrude
 (Intercept)       group2       group3       group4
0.000000e+00 0.000000e+00 0.000000e+00 6.428191e-13
> # or value
> orSnapMorCrude <- exp(coef(modelSnapMorCrude))
> orSnapMorCrude
(Intercept)      group2      group3      group4
  0.2173914   1.9073151   5.2571436   1.6372876
> # 95% ci
> ciSnapMorCrude <- exp(confint(modelSnapMorCrude))
> ciSnapMorCrude
                2.5 %    97.5 %
(Intercept) 0.1966478 0.2403232
group2      1.6859947 2.1576882
group3      4.4652693 6.1894495
group4      1.4314099 1.8727764
```


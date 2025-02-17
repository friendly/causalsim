
<!-- README.md is generated from README.Rmd. Please edit that file -->

# causalsim

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The `causalsim` package uses a matrix containing the coefficients and
standard deviations of the unique independent components of a linear
causal DAG to generate the marginal covariance matrix and to calculate
the value of coefficients of linear models applied to a population
generated by the causal DAG.

## Installation

You can install the development version of causalsim like so:

``` r
remotes::install_github("gmonette/causalsim")
```

## Example

This example creates a DAG consisting of a collection of paths among the
following variables in a causal analysis. The variables included here
are:

-   **x** the focal predictor, e.g., a treatment variable
-   **y** the outcome
-   **m** a mediator variable
-   **i** an instrumental variable, i.e., a predictor of only **x**
-   **c** a covariate, i.e., a predictor of **y** one might also want to
    take into account
-   **zr**
-   **zc** a central confounder, providing a backdoor path from **x**
    through **zl** to **y** through **zr**
-   **zl**

The DAG to be studied here is:

<!-- # why isn't this found? -->

<img src="man/figures/coefx-ex-dag.png" style="width:60.0%" />

In `causalsim` this DAG is to be setup as a square matrix, `mat`, whose
rows and columns are the 8 variables shown in the figure. The entries
are:

-   `mat[i, j]` = coefficient on the path from variable `j` to `i`
-   `mat[i, i]` = error variance associated with variable `i`

``` r
library(causalsim)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

nams <- c('zc','zl','zr','c','x','y','m','i')
mat <- matrix(0, length(nams), length(nams))
rownames(mat) <- nams
colnames(mat) <- nams

# set up paths: each value is the regression coefficient on the path

# direct effect, x -> y
mat['y','x'] <- 3

# indirect effect, x -> m -> y
mat['m','x'] <- 1
mat['y','m'] <- 1

# Instrumental variable 
mat['x','i'] <- 2

# 'Covariate'
mat['y','c'] <- 1

# confounding back-door path
mat['zl','zc'] <- 2 
mat['zr','zc'] <- 2
mat['x','zl'] <- 1
mat['y','zr'] <- 2

# independent error
diag(mat) <- 2

mat # not in lower diagonal form   
#>    zc zl zr c x y m i
#> zc  2  0  0 0 0 0 0 0
#> zl  2  2  0 0 0 0 0 0
#> zr  2  0  2 0 0 0 0 0
#> c   0  0  0 2 0 0 0 0
#> x   0  1  0 0 2 0 0 2
#> y   0  0  2 1 3 2 1 0
#> m   0  0  0 0 1 0 2 0
#> i   0  0  0 0 0 0 0 2
```

This matrix represents a DAG only if it has no cycles, which means it
can be permuted to lower-diagonal form.

``` r
dag <- to_dag(mat) # can be permuted to lower-diagonal form
dag
#>    i zc zl x m c zr y
#> i  2  0  0 0 0 0  0 0
#> zc 0  2  0 0 0 0  0 0
#> zl 0  2  2 0 0 0  0 0
#> x  2  0  1 2 0 0  0 0
#> m  0  0  0 1 2 0  0 0
#> c  0  0  0 0 0 2  0 0
#> zr 0  2  0 0 0 0  2 0
#> y  0  0  0 3 1 1  2 2
#> attr(,"class")
#> [1] "dag"    "matrix" "array"
```

`covld()` computes the overall covariance matrix generated by the
coefficients of a linear DAG.

``` r
covld(dag)
#>     i zc  zl   x   m c  zr   y
#> i   4  0   0   8   8 0   0  32
#> zc  0  4   8   8   8 0   8  48
#> zl  0  8  20  20  20 0  16 112
#> x   8  8  20  40  40 0  16 192
#> m   8  8  20  40  44 0  16 196
#> c   0  0   0   0   0 4   0   4
#> zr  0  8  16  16  16 0  20 104
#> y  32 48 112 192 196 4 104 988
```

Given a linear DAG, `coefx()` finds the population regression
coefficients using data with the marginal covariance structure implied
by the DAG.

The model `lm(y ~ x)` gives a biased estimate of
![\\beta_x](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Cbeta_x "\beta_x"),
whose true value is `mat['y','x'] =` 3. `coefx()` returns a list, but it
can be coerced to a dataframe.

``` r
coefx(y ~ x, dag)                 # with confounding
#> $beta
#> [1] 4.8
#> 
#> $sd_e
#> [1] 8.149
#> 
#> $sd_x_avp
#> [1] 6.325
#> 
#> $sd_betax_factor
#> [1] 1.288
#> 
#> $fmla
#> y ~ x
#> 
#> $label
#> [1] "y ~ x"
#> 
#> attr(,"class")
#> [1] "coefx"

# print it nicely
as.data.frame(coefx(y ~ x, dag))  # with confounding
#>   beta_x  sd_e sd_x_avp sd_factor label
#> 1    4.8 8.149    6.325     1.288 y ~ x
```

We can examine the coefficients for any model including other variables
in addition to **x**.

``` r
as.data.frame(coefx(y ~ x + zc, dag))              # blocking back-door path
#>   beta_x  sd_e sd_x_avp sd_factor      label
#> x      4 5.292    4.899      1.08 y ~ x + zc
as.data.frame(coefx(y ~ x + zr, dag))              # blocking with lower SE
#>   beta_x  sd_e sd_x_avp sd_factor      label
#> x      4 3.464    5.215    0.6642 y ~ x + zr
as.data.frame(coefx(y ~ x + zl, dag))              # blocking with worse SE
#>   beta_x  sd_e sd_x_avp sd_factor      label
#> x      4 6.387    4.472     1.428 y ~ x + zl
as.data.frame(coefx(y ~ x + zr + c, dag))          # adding a 'covariate'
#>   beta_x  sd_e sd_x_avp sd_factor          label
#> x      4 2.828    5.215    0.5423 y ~ x + zr + c
as.data.frame(coefx(y ~ x + zr + m, dag))          # including a mediator
#>   beta_x  sd_e sd_x_avp sd_factor          label
#> x      3 2.828    1.867     1.515 y ~ x + zr + m
as.data.frame(coefx(y ~ x + zl + i, dag))          # including an instrument
#>   beta_x  sd_e sd_x_avp sd_factor          label
#> x      4 6.387        2     3.194 y ~ x + zl + i
as.data.frame(coefx(y ~ x + zl + i + c, dag))      # I and C
#>   beta_x  sd_e sd_x_avp sd_factor              label
#> x      4 6.066        2     3.033 y ~ x + zl + i + c
```

It is more convenient to set up a collection of formulas as a list, and
then run `coefx` on each to give a dataframe containing all results.

``` r
fmlas <- list(
  y ~ x, 
  y ~ x + zc, 
  y ~ x + zr, 
  y ~ x + zl,
  y ~ x + zr + c, 
  y ~ x + zr + m, 
  y ~ x + zl + i,
  y ~ x + zl + i + c
)

fmlas %>% 
  lapply(coefx, dag) %>% 
  lapply(as.data.frame) %>% 
  do.call(rbind.data.frame, .) -> df

df
#>    beta_x  sd_e sd_x_avp sd_factor              label
#> 1     4.8 8.149    6.325    1.2884              y ~ x
#> x     4.0 5.292    4.899    1.0801         y ~ x + zc
#> x1    4.0 3.464    5.215    0.6642         y ~ x + zr
#> x2    4.0 6.387    4.472    1.4283         y ~ x + zl
#> x3    4.0 2.828    5.215    0.5423     y ~ x + zr + c
#> x4    3.0 2.828    1.867    1.5146     y ~ x + zr + m
#> x5    4.0 6.387    2.000    3.1937     y ~ x + zl + i
#> x6    4.0 6.066    2.000    3.0332 y ~ x + zl + i + c
```

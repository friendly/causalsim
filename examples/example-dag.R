# DAG from daggity

library(tidyverse)
library(dagitty)
library(ggdag)

# example_dag0 <- dagitty(`
#   dag {
#     bb="0,0,1,1"
#     C [pos="0.765,0.642"]
#     I [pos="0.200,0.135"]
#     M [pos="0.623,0.196"]
#     X [exposure,pos="0.345,0.278"]
#     Y [outcome,pos="0.564,0.491"]
#     Zc [pos="0.180,0.531"]
#     Zl [pos="0.082,0.372"]
#     Zr [pos="0.385,0.587"]
#     C -> Y
#     I -> X
#     M -> Y
#     X -> M
#     X -> Y
#     Zc -> Zl
#     Zc -> Zr
#     Zl -> X
#     Zr -> Y
#     }
# `)

# using auto layout
example_dag0 <- dagitty(`
  dag {
  bb="-5.452,-4.164,4.244,5.494"
  C [pos="0.880,4.689"]
  I [pos="-4.644,-1.592"]
  M [pos="-2.402,1.869"]
  X [exposure,pos="-1.674,-0.841"]
  Y [outcome,pos="0.384,1.709"]
  Zc [pos="3.436,-2.593"]
  Zl [pos="0.528,-3.359"]
  Zr [pos="3.405,0.381"]
  C -> Y
  I -> X
  M -> Y
  X -> M
  X -> Y
  Zc -> Zl
  Zc -> Zr
  Zl -> X
  Zr -> Y
  }
`)

# create tidy DAG
example_dag |>
tidy_dagitty() %>%
  # Set Node Status
  node_status() %>%
  # Set node adjacency
  node_ancestors(.var = "Y")

ggdag(example_dag)

# Minimal sufficient adjustment sets for estimating the total effect of X on Y:
#    Zc
#    Zl
#    Zr
# Minimal sufficient adjustment sets for estimating the direct effect of X on Y:
#    M, Zc
#    M, Zl
#    M, Zr

# The model implies the following conditional independences:
#
#    X ⊥ Zc | Zl
#    X ⊥ Zr | Zc
#    X ⊥ Zr | Zl
#    X ⊥ C
#    Y ⊥ I | X, Zl
#    Y ⊥ I | X, Zc
#    Y ⊥ I | X, Zr
#    Y ⊥ Zl | X, Zc
#    Y ⊥ Zl | X, Zr


# specify the paths
example_dag <- dagify(
	Y ~ X + M + C + Zr,
	M ~ X,
	X ~ Zl + I,
	Zl ~ Zc,
	Zr ~ Zc, 
	exposure = "X",
	outcome = "Y"
)

ggdag(example_dag)

# create tidy DAG
paths |>
  tidy_dagitty() |>
  # Set Node Status
  node_status() |>
  # Set node adjacency
  node_ancestors(.var = "Y")

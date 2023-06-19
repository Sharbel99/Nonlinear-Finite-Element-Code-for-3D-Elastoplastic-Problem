# Nonlinear-Finite-Element-Code-for-3D-Elastoplastic-Problem
A program showcasing the process of solving a 3D Elastoplastic problem in an 8-node cubic element using the Newton-Raphson method with the return mapping algorithm.
The shear case is presented. Various stress, strain, tangent and other components are plotted in addition to the residual log.

## Description of the problem
The code solves the problem having the following energy function: 
```math
 U \left( J^e \right) = \dfrac{1}{2} \kappa \left(\dfrac{1}{2}\left({J^e}^2 -1 \right) - ln J^e \right)
```
```math
\bar{W}\left(\bar{\textbf{b}}^e\right) = \mu_1 \left(tr \left[\bar{\textbf{b}}^e\right] -3 \right)
```
For the plastic part, we use the J2-flow theory
## Instructions
First run the input file (Input_shear.m) then run FEA_Program.m

To edit the code to run a different energy functional, edit the parameters in the input file, and edit the residual and tangent in Elast3d_Elem.m

To change the plots, edit FEA_Program.m

## Reference
Simo, J. C., & Hughes, T. J. (2006). Computational inelasticity (Vol. 7). Springer Science & Business Media.

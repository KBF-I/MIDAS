/* Context for SSXLS
   -- semismooth (SS) - function not differentiable
                      - merit function continuously differentiable
                      - Fischer-Burmeister reformulation of complementarity
                        - Billups composition for two finite bounds
   -- infeasible (I)  - iterates not guaranteed to remain within bounds
   -- feasible (F)    - iterates guaranteed to remain within bounds
   -- linesearch (LS) - Armijo rule on direction

 Many other reformulations are possible and combinations of
 feasible/infeasible and linesearch/trust region are possible.

 Basic theory
   Fischer-Burmeister reformulation is semismooth with a continuously
   differentiable merit function and strongly semismooth if the F has
   lipschitz continuous derivatives.

   Every accumulation point generated by the algorithm is a stationary
   point for the merit function.  Stationary points of the merit function
   are solutions of the complementarity problem if
     a.  the stationary point has a BD-regular subdifferential, or
     b.  the Schur complement F'/F'_ff is a P_0-matrix where ff is the
         index set corresponding to the free variables.

   If one of the accumulation points has a BD-regular subdifferential then
     a.  the entire sequence converges to this accumulation point at
         a local q-superlinear rate
     b.  if in addition the reformulation is strongly semismooth near
         this accumulation point, then the algorithm converges at a
         local q-quadratic rate.

 The theory for the feasible version follows from the feasible descent
 algorithm framework.

 References:
+ * - Billups, "Algorithms for Complementarity Problems and Generalized
     Equations," Ph.D thesis, University of Wisconsin - Madison, 1995.
. * - De Luca, Facchinei, Kanzow, "A Semismooth Equation Approach to the
     Solution of Nonlinear Complementarity Problems," Mathematical
     Programming, 75, pages 407-439, 1996.
. * - Ferris, Kanzow, Munson, "Feasible Descent Algorithms for Mixed
     Complementarity Problems," Mathematical Programming, 86,
     pages 475-497, 1999.
. * - Fischer, "A Special Newton-type Optimization Method," Optimization,
     24, pages 269-284, 1992
- * - Munson, Facchinei, Ferris, Fischer, Kanzow, "The Semismooth Algorithm
     for Large Scale Complementarity Problems," Technical Report 99-06,
     University of Wisconsin - Madison, 1999.
*/

#ifndef __TAO_SSLS_H
#define __TAO_SSLS_H
#include <petsc/private/taoimpl.h>

typedef struct {
  Vec ff;       /* fischer function */
  Vec dpsi;     /* gradient of psi */

  Vec da;       /* work vector for subdifferential calculation (diag pert) */
  Vec db;       /* work vector for subdifferential calculation (row scale) */
  Vec dm;   /* work vector for subdifferential calculation (mu vector) */
  Vec dxfree;

  Vec t1;       /* work vector */
  Vec t2;       /* work vector */

  Vec r1,r2,r3,w; /* work vectors */

  PetscReal merit; /* merit function value (norm(fischer)) */
  PetscReal merit_eqn;
  PetscReal merit_mu;

  PetscReal delta;
  PetscReal rho;

  PetscReal rtol;       /* Solution tolerances */
  PetscReal atol;

  PetscReal identifier; /* Active-set identification */

  /* Interior-point method data */
  PetscReal mu_init; /* initial smoothing parameter value */
  PetscReal mu;      /* smoothing parameter */
  PetscReal dmu;     /* direction in smoothing parameter */
  PetscReal mucon;   /* smoothing parameter constraint */
  PetscReal d_mucon; /* derivative of smoothing constraint with respect to mu */
  PetscReal g_mucon; /* gradient of merit function with respect to mu */

  Mat J_sub, Jpre_sub; /* subset of jacobian */
  Vec f;        /* constraint function */

  IS fixed;
  IS free;
} TAO_SSLS;

PetscErrorCode TaoSetFromOptions_SSLS(PetscOptionItems *,Tao);
PetscErrorCode TaoView_SSLS(Tao,PetscViewer);

PetscErrorCode Tao_SSLS_Function(TaoLineSearch, Vec, PetscReal *, void *);
PetscErrorCode Tao_SSLS_FunctionGradient(TaoLineSearch, Vec, PetscReal *, Vec, void *);

#endif


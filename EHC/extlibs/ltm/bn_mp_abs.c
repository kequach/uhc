#include "tommath.h"
#ifdef BN_MP_ABS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis
 *
 * LibTomMath is a library that provides multiple-precision
 * integer arithmetic as well as number theoretic functionality.
 *
 * The library was designed directly after the MPI library by
 * Michael Fromberger but has been written from scratch with
 * additional optimizations in place.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 *
 * Tom St Denis, tomstdenis@gmail.com, http://math.libtomcrypt.com
 */

/* b = |a| 
 *
 * Simple function copies the input and fixes the sign to positive
 */
int
mp_abs (mp_int * a, mp_int * b)
{
  int     res;

  /* copy a to b */
  if (a != b) {
     if ((res = mp_copy (a, b)) != MP_OKAY) {
       return res;
     }
  }

  /* force the sign of b to positive */
  SET_SIGN(b,MP_ZPOS);

  return MP_OKAY;
}
#else

MP_DUMMY_LINKER_DEF

#endif

/* $Source: /cvs/libtom/libtommath/bn_mp_abs.c,v $ */
/* $Revision: 1.3 $ */
/* $Date: 2006/03/31 14:18:44 $ */

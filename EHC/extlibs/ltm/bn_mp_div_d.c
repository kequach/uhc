#include "tommath.h"
#ifdef BN_MP_DIV_D_C
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

static int s_is_power_of_two(mp_digit b, int *p)
{
   int x;

   for (x = 1; x < DIGIT_BIT; x++) {
      if (b == (((mp_digit)1)<<x)) {
         *p = x;
         return 1;
      }
   }
   return 0;
}

/* single digit division (based on routine from MPI) */
int mp_div_d (mp_int * a, mp_digit b, mp_int * c, mp_digit * d)
{
  MP_LOCAL_DEF(q);
  mp_word w;
  mp_digit t;
  int     res, ix;

  /* cannot divide by zero */
  if (b == 0) {
     return MP_VAL;
  }

  /* quick outs */
  if (b == 1 || mp_iszero(a) == 1) {
     if (d != NULL) {
        *d = 0;
     }
     if (c != NULL) {
        return mp_copy(a, c);
     }
     return MP_OKAY;
  }

  /* power of two ? */
  if (s_is_power_of_two(b, &ix) == 1) {
     if (d != NULL) {
        *d = DIGIT(a,0) & ((((mp_digit)1)<<ix) - 1);
     }
     if (c != NULL) {
        // printf( "mp_div_d mp_div_2d:\n" ) ;
        return mp_div_2d(a, ix, c, NULL);
     }
     return MP_OKAY;
  }

#ifdef BN_MP_DIV_3_C
  /* three? */
  if (b == 3) {
     // printf( "mp_div_d mp_div_3:\n" ) ;
     return mp_div_3(a, c, d);
  }
#endif

  /* no easy answer [c'est la vie].  Just division */
  mp_local_init_size(MP_LOCAL_REF(q), USED(a), res) ;
  if (res != MP_OKAY) {
     return res;
  }
  
  SET_USED(MP_LOCAL_REF(q),USED(a));
  SET_SIGN(MP_LOCAL_REF(q),SIGN(a));
  w = 0;
  for (ix = USED(a) - 1; ix >= 0; ix--) {
     w = (w << ((mp_word)DIGIT_BIT)) | ((mp_word)DIGIT(a,ix));
     
     if (w >= b) {
        t = (mp_digit)(w / b);
        w -= ((mp_word)t) * ((mp_word)b);
      } else {
        t = 0;
      }
      SET_DIGIT(MP_LOCAL_REF(q),ix,(mp_digit)t);
  }
  
  if (d != NULL) {
     *d = (mp_digit)w;
  }
  
  if (c != NULL) {
     mp_clamp(MP_LOCAL_REF(q));
     mp_local_assignfrom(c,q) ;
  }
  mp_local_clear(q);
  
  return res;
}

#else

MP_DUMMY_LINKER_DEF

#endif

/* $Source: /cvs/libtom/libtommath/bn_mp_div_d.c,v $ */
/* $Revision: 1.3 $ */
/* $Date: 2006/03/31 14:18:44 $ */

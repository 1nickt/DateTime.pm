/* Copyright (c) 2003 Dave Rolsky
   All rights reserved.
   This program is free software; you can redistribute it and/or
   modify it under the same terms as Perl itself.  See the LICENSE
   file that comes with this distribution for more details. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* 2 ** 28 - 307 */
#define RANGE_CUTOFF        (268435456 - 307)
#define DAYS_PER_400_YEARS  146097
#define DAYS_PER_4_YEARS    1461
#define MARCH_1             306


MODULE = DateTime       PACKAGE = DateTime

void
_rd2greg(self, d)
     SV* self;
     IV d;

     PREINIT:
        IV y, m;
        IV c;
        IV yadj = 0;

     PPCODE:
        if (d > RANGE_CUTOFF) {
          yadj = (d - DAYS_PER_400_YEARS + MARCH_1 ) / DAYS_PER_400_YEARS + 1;
          d -= (yadj * DAYS_PER_400_YEARS) - MARCH_1;
        } else {
          d += MARCH_1;

          if (d <= 0) {
            yadj = -1 * (((-1 * d) / DAYS_PER_400_YEARS) + 1);
            d -= yadj * DAYS_PER_400_YEARS;
          }
        }

        /* c is century */
        c =  ((d * 4) - 1) / DAYS_PER_400_YEARS;
        d -= c * DAYS_PER_400_YEARS / 4;
        y =  ((d * 4) - 1) / DAYS_PER_4_YEARS;
        d -= y * DAYS_PER_4_YEARS / 4;
        m =  ((d * 12) + 1093) / 367;
        d -= ((m * 367) - 1094) / 12;
        y += (c * 100) + (yadj * 400);
        if (m > 12) {
          ++y;
          m -= 12;
        }

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(y)));
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSViv(d)));

void
_greg2rd(self, y, m, d)
     SV* self;
     IV y;
     IV m;
     IV d;

     PREINIT:
        IV adj;

     PPCODE:
        if (m <= 2) {
          adj = (14 - m) / 12;
          y -= adj;
          m += 12 * adj;
        } else if (m > 14) {
          adj = (m - 3) / 12;
          y += adj;
          m -= 12 * adj;
        }

        if (y < 0) {
          adj = (399 - y) / 400;
          d -= DAYS_PER_400_YEARS * adj;
          y += 400 * adj;
        }

        d += (m * 367 - 1094) /
             12 + y % 100 * DAYS_PER_4_YEARS /
             4 + (y / 100 * 36524 + y / 400) - MARCH_1;

        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(d)));

void
_seconds_as_components(self, secs)
     SV* self;
     int secs;

     PREINIT:
        int h, m, s;

     PPCODE:
        h = secs / 3600;
        secs -= h * 3600;

        m = secs / 60;

        s = secs - (m * 60);

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(h)));
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSViv(s)));

void _normalize_seconds(days, secs)
     SV* days;
     SV* secs;

     PPCODE:
        int d = SvIV(days);
        int s = SvIV(secs);
        int adj;

        if (s < 0) {
          adj = (s - 86399) / 86400;
        } else {
          adj = s / 86400;
        }

        d += adj;
        s -= adj * 86400;

        sv_setiv(days, (IV) d);
        sv_setiv(secs, (IV) s);

void _time_as_seconds(self, h, m, s)
     SV* self;
     IV h;
     IV m;
     IV s;

     PPCODE:
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(h * 3600 + m * 60 + s)));

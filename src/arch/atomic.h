/*
 *  Atomic ops
 *  Copyright (C) 2008 Andreas Öman
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef HTSATOMIC_H__
#define HTSATOMIC_H__

/**
 * Atomically add 'incr' to *ptr and return the previous value
 */
#if defined(__i386__) || defined(__x86_64__)
static inline int
atomic_add(volatile int *ptr, int incr)
{
  int r;
  asm volatile("lock; xaddl %0, %1" :
	       "=r"(r), "=m"(*ptr) : "0" (incr), "m" (*ptr) : "memory");
  return r;
}
#elif defined(GEKKO)

#include <ogc/machine/processor.h>

static inline int
atomic_add(volatile int *ptr, int incr)
{
  int r, level;

  /* XXX: Use atomic ops, but I need to read more about that on PPC */

  _CPU_ISR_Disable(level);

  r = *ptr;
  *ptr = *ptr + incr;

  _CPU_ISR_Restore(level);

  return r;
}
#elif defined(__ppc__)

/* somewhat based on code from darwin gcc  */
static inline int
atomic_add (volatile int *ptr, int incr)
{
  int tmp, res;
  asm volatile("0:\n"
               "lwarx  %1,0,%2\n"
               "add%I3 %0,%1,%3\n"
               "stwcx. %0,0,%2\n"
               "bne-   0b\n"
               : "=&r"(tmp), "=&b"(res)
               : "r" (ptr), "Ir"(incr)
               : "cr0", "memory");
  
  return res;
}

#else
#error Missing atomic ops
#endif

#endif /* HTSATOMIC_H__ */

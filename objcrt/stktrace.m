/* Copyright (c) 2016 D. Mackay. All rights reserved. */
/*
 * Portable Object Compiler (c) 1997,98,99,2000,01,04,14.  All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "objcrt.h"

/*****************************************************************************
 *
 * Stack Tracing
 *
 * This is platform dependent code that is nice to have (when possible), but
 * it is not essential ...  It is just to print a trace when a -error: message
 * is sent.
 *
 * The default handler (if no platform specific code is available) simply
 * prints a message that says to use a debugger to see the trace.
 *
 ****************************************************************************/

#if (defined(__LCC__) && defined(WIN32)) ||                                    \
    ((i386 || m68k) &&                                                         \
     (__FreeBSD__ || linux || __NetBSD__ || __NeXT__ || __svr4__))

/* stack frame layout (for messages) */

typedef struct _msgframe
{
    struct _msgframe * prev; /* link to prev frame */
    id (*ret) ();            /* return address from subroutine */
    struct _argframe
    {
        id receiver; /* id of receiver */
        SEL cmd;     /* message selector */
        int arg;     /* first message argument */
    } argfrm;
} * msgframe;

#ifdef m68k
#define ispointer(addr) (((unsigned)addr & 0x1) == 0)
#else
#define ispointer(addr) 1 /* (((unsigned)addr&0x1)==0) */
#endif

#define instack(addr) (((unsigned)(addr)&0xfff00000) != 0)
#define isstackframe(fp) (ispointer (fp) && instack (fp) && (fp) < (fp)->prev)
#define firstargpos ((unsigned)&(((msgframe)0)->argfrm.receiver))
#define getframe(firstArg) ((msgframe) ((unsigned)&firstArg - firstargpos))

#define PRINT_STACK_BACKTRACE 1
#endif

#if 0 && defined(sparc)

/* stack frame layout (for messages) */

typedef struct _msgframe
  {
    unsigned l0, l1, l2, l3, l4, l5, l6, l7;
    unsigned i0, i1, i2, i3, i4, i5;
    struct _msgframe *prev;	/* i6 = link to prev frame */
    unsigned i7;
    char *hidden;
    struct _argframe
      {
	id receiver;		/* id of receiver */
	SEL cmd;		/* message selector */
	unsigned o2, o3, o4, o5, o6, o7;
      }
    argfrm;
  }
 *msgframe;

#define ispointer(addr) (((unsigned)addr & 0x1) == 0)
#define instack(addr) (((unsigned)(addr)&0xfff00000) != 0)
#define isstackframe(fp) (ispointer (fp) && instack (fp) && (fp) < (fp)->prev)
#define firstargpos ((unsigned)&(((msgframe)0)->argfrm.receiver))
#define getframe(firstArg) ((msgframe) ((unsigned)&firstArg - firstargpos))

#define PRINT_STACK_BACKTRACE 1
#endif

#define PRNSTKMAX 100

void EXPORT prnstack (FILE * firstArg)
{
#ifndef PRINT_STACK_BACKTRACE
    fprintf (firstArg, "(Use a debugger to see a stack backtrace).\n");
    fflush (firstArg);
#else
    FILE * stream  = firstArg;
    msgframe pf, f = getframe (firstArg);
    int nsels      = 0;
    SEL sels[PRNSTKMAX];

    fprintf (stream, "Message backtrace:\n");

    for (pf = f->prev; isstackframe (pf) && nsels < PRNSTKMAX;
         f = pf, pf = pf->prev)
    {
        SEL s = f->argfrm.cmd;
        if (isminmaxsel (s) && ispointer (s) && selUid (s) != NULL)
            sels[nsels++] = s;
    }

    while (nsels--)
        fprintf (stream, " %.80s\n", sels[nsels]);
#endif
}
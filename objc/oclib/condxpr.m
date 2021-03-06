/*
 * Copyright (c) 1998 David Stes.
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

#include <stdlib.h>
#include <assert.h>
#include "Object.h"
#include "node.h"
#include "expr.h"
#include "condxpr.h"
#include "var.h"
#include "scalar.h"

@implementation CondExpr

- expr:aRcvr
{
    expr = aRcvr;
    return self;
}

- lhs:args
{
    lhs = args;
    return self;
}

- rhs:args
{
    rhs = args;
    return self;
}

- (int)lineno { return [expr lineno]; }

- filename { return [expr filename]; }

- typesynth
{
    if (lhs)
        type = [lhs type];
    else
        type = [rhs type];
#if 0
  /* warn about (t)?t:NULL */
  if (![[rhs type] isEqual:type])
    warn("types in conditional expr not equal");
#endif
    return self;
}

- synth
{
    expr = [expr synth];
    if (lhs)
        lhs = [lhs synth];
    rhs     = [rhs synth];
    return self;
}

- gen
{
    [expr gen];
    gc ('?');
    if (lhs)
        [lhs gen]; /* gnu extension x?:y */
    gc (':');
    [rhs gen];
    return self;
}

- st80
{
    gc ('(');
    gc ('(');
    [expr st80];
    gc (')');
    gs ("ifTrue:[");
    if (lhs)
        [lhs st80];
    gs ("]ifFalse:[");
    [rhs st80];
    gc (']');
    gc (')');
    return self;
}
@end

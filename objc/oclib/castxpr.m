/*
 * Copyright (c) 1998,2000 David Stes.
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
#include "castxpr.h"

@implementation CastExpr

- expr:aRcvr
{
    expr = aRcvr;
    return self;
}

- (int)lineno { return [cast lineno]; }

- filename { return [cast filename]; }

- (BOOL)isconstexpr { return [expr isconstexpr]; }

- cast:args
{
    cast = args;
    return self;
}

- typesynth
{
    expr = [expr typesynth];
    type = cast;
    return self;
}

- synth
{
    expr = [expr synth];
    return self;
}

- gen
{
    gl ([self lineno], [[self filename] str]);
    gc ('(');
    [cast gen];
    gc (')');
    [expr gen];
    return self;
}

- go { return [expr go]; }

@end

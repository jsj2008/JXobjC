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
#include "commaxpr.h"

@implementation CommaExpr

- lhs { return lhs; }

- lhs:aRcvr
{
    lhs = aRcvr;
    return self;
}

- rhs { return rhs; }

- rhs:args
{
    rhs = args;
    return self;
}

- (int)lineno { return [lhs lineno]; }

- filename { return [lhs filename]; }

- typesynth
{
    lhs  = [lhs typesynth];
    rhs  = [rhs typesynth];
    type = [rhs type];
    return self;
}

- synth
{
    lhs = [lhs synth];
    rhs = [rhs synth];
    return self;
}

- gen
{
    [lhs gen];
    gc (',');
    [rhs gen];
    return self;
}

@end

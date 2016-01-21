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
 *
 */

#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "Object.h"
#include "OCString.h"
#include "node.h"
#include "expr.h"
#include "binxpr.h"
#include "arrowxpr.h"
#include "symbol.h"
#include "type.h"

@implementation ArrowExpr

+ new { return [[super new] op:"->"]; }

- typesynth
{
    assert ([rhs isKindOf:(id)[Symbol class]]);
    lhs = [lhs typesynth];

    if ([[lhs type] isid])
    {
        if ([rhs isEqual:@"isa"])
            type = t_id;
        else
            type = t_unknown;
    }
    else
    {
        type = [[lhs type] star];
        type = [type dot:rhs];
    }

    if (!type)
    {
        warnat (rhs, "Structure has no field '%s'", [rhs str]);
        type = t_void;
    }

    return self;
}

@end

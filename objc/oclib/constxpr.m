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
#include "OrdCltn.h"
#include "OCString.h"
#include "node.h"
#include "symbol.h"
#include "expr.h"
#include "constxpr.h"
#include "type.h"
#include "var.h"
#include "scalar.h"

@implementation ConstantExpr

- (BOOL)isconstexpr { return YES; }

- identifier:aNode
{
    identifier = aNode;
    return self;
}

- stringchain:aList
{
    stringchain = aList;
    return self;
}

- identifier { return identifier; }

- stringchain { return stringchain; }

- (BOOL)isEqual:x
{
    assert (identifier);
    return [identifier isEqual:[x identifier]];
}

- (int)lineno
{
    if (identifier)
        return [identifier lineno];
    return [[stringchain at:0] lineno];
}

- filename
{
    if (identifier)
        return [identifier filename];
    return [[stringchain at:0] filename];
}

- (int)asInt { return [identifier asInt]; }

- synth { return self; }

- typesynth
{
    if (identifier)
        type = [identifier type];
    if (stringchain)
        type = t_str;
    if (!type)
        type = t_unknown;
    return self;
}

- gen
{
    if (identifier)
        [identifier gen];
    if (stringchain)
        [stringchain elementsPerform:@selector (gen)];
    return self;
}

- concatstringchain
{
    int i, n;
    Symbol * s = [Symbol new];
    for (i = 0, n = [stringchain size]; i < n; i++)
    {
        id o = [stringchain at:i];
        [s concat:o];
    }
    return [s unescape];
}
- st80
{
    if (identifier)
        [identifier st80];
    if (stringchain)
        [stringchain elementsPerform:_cmd];
    return self;
}

@end

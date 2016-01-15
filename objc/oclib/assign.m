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
#include "node.h"
#include "expr.h"
#include "binxpr.h"
#include "identxpr.h"
#include "assign.h"
#include "type.h"
#include "def.h"
#include "classdef.h"
#include "options.h"
#include "trlunit.h"
#include "arrowxpr.h"
#include "dotxpr.h"
#import "prdotxpr.h"

@implementation Assignment

- (int)lineno { return [lhs lineno]; }

- filename { return [lhs filename]; }

- typesynth
{
    lhs  = [lhs typesynth];
    type = [lhs type];
    return self;
}

- synth
{
    lhs = [lhs synth];
    /* Here, we test if LHS is a property dot-accessor.
     * If so, then tell it to become a setter accessor and associate RHS
     * as its argument. */
    if ([lhs isKindOf:DotPropertyExpr])
    {
        [lhs setSetExpr:rhs];
        [lhs synth];
        [lhs setReplaced:YES];
        subsumed = YES;
        return self;
    }
    [super synth];
    if (curdef && [curdef ismethdef] && [lhs isidentexpr] &&
        strcmp ([lhs str], "self") == 0)
    {
        [trlunit usingselfassign:YES];
        if (!o_selfassign)
        {
            id sym = [lhs identifier];

            fatalat (sym,
                     "assignment to 'self' not allowed with -noSelfAssign");
        }
        else
        {
            classdef = curclassdef;
            isselfassign++;
            /* we cannot cast the lhs to 'id' (that is not ANSI C) */
            [lhs lhsself:YES]; /* no 'id' cast at the lhs */
        }
    }
    if (o_refcnt)
    {
        if (isselfassign || [[lhs type] isrefcounted])
            isidassign++;
    }

    if ([[lhs type] isNamedClass] && [[rhs type] isNamedClass])
    {
        ClassDef *lhsCls = [[lhs type] getClass],
                 *rhsCls = [[rhs type] getClass];
        if (![lhsCls checkAssign:rhsCls])
            warn ("downcasting object of parent class %s to derived class %s",
                  [lhsCls classname], [rhsCls classname]);
        else if (![lhsCls isRelated:rhsCls])
            warnat (rhs,
                    "assigning object of unrelated class %s to identifier of "
                    "class %s",
                    [rhsCls classname], [lhsCls classname]);
    }

    return self;
}

- gen
{
    if (subsumed)
        return [lhs forcegen];
    if (isidassign)
    {
        gl ([lhs lineno], [[lhs filename] str]);
        gs ("idassign((id*)(&(");
        [lhs gen];
        gs (")),(id)(");
        [rhs gen];
        gs ("))");
        return self;
    }
    if (isselfassign)
    {
        [lhs gen];
        gs (op);
        /* cast rhs to type of 'self' */
        if (!o_otb)
        {
            gf ("(struct %s*)", [classdef privtypename]);
        }
        else
        {
            gf ("(struct %s*)", [classdef otbtypename]);
        }
        gc ('(');
        [rhs gen];
        gc (')');
        return self;
    }
    else if (rcast)
    {
        [lhs gen];
        gs (op);
        gc ('(');
        [rcast genabstrtype];
        gs (")(");
        [rhs gen];
        gc (')');
        return self;
    }
    else
        return [super gen];
}

- st80
{
    [lhs st80];
#ifdef ST80
    gc ('_');
#else
    gs (":=");
#endif
    [rhs st80];
    return self;
}

@end

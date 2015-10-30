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

#include "config.h"
#include <stdlib.h>
#include <assert.h>
#include <stdio.h> /* FILE */
#include "Object.h"
#include "node.h"
#include "decl.h"
#include "initdecl.h"
#include "expr.h"
#include "listxpr.h"
#include "options.h"
#include "util.h"
#include "binxpr.h"
#include "arrowxpr.h"
#include "dotxpr.h"

@implementation InitDecl

- (BOOL)isinit { return YES; }

- (BOOL)islistinit { return [initializer isKindOf:(id)[ListExpr class]]; }

- (BOOL)isfunproto { return NO; }

- cast:aCast
{
    cast = aCast;
    return self;
}

- decl { return decl; }

- decl:aRcvr
{
    decl = aRcvr;
    return self;
}

- initializer { return initializer; }

- initializer:aDecl
{
    initializer = aDecl;
    return self;
}

- initnil
{
    initnil     = YES;
    initializer = e_nil;
    return self;
}

- initnilWithType:typ
{
    initnil     = YES;
    initializer = mkcastexpr (typ, e_nil);
    return self;
}

- incref
{
    incref++;
    return self;
}

- abstrdecl { return [decl abstrdecl]; }

- identifier { return [decl identifier]; }

- synth
{
    [cast synth];
    [decl synth];
    [initializer synth];
    return self;
}

- synthinits
{
    [initializer synth];
    if (![initializer isKindOf:DotExpr] && ![initializer isKindOf:ArrowExpr] &&
        ![initializer isKindOf:ListExpr] && [[initializer type] isid])
        cast = [initializer type];
    return self;
}

- hide:x rename:y
{
    [decl hide:x rename:y];
    return self;
}

- gen
{
    [decl gen];
    gc ('=');
    if (initnil)
    {
        [initializer sgen];
    }
    else
    {
        if (cast)
        {
            gc ('(');
            [cast genabstrtype];
            gc (')');
        }
        if (incref)
            gs ("idincref((id)"); /* just like in assignment */
        [initializer gen];
        if (incref)
            gc (')');
    }
    return self;
}

- st80
{
    [decl st80];
    return self;
}

- st80inits
{
    [decl st80];
#ifdef ST80
    gc ('_');
#else
    gs (":=");
#endif
    [initializer st80];
    gs (".\n");
    return self;
}

@end

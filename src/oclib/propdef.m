
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
 * $Id: methdef.m,v 1.1.1.1 2000/06/07 21:09:25 stes Exp $
 */

#include "config.h"
#include <stdlib.h>
#include <assert.h>
#ifndef __OBJECT_INCLUDED__
#define __OBJECT_INCLUDED__
#include <stdio.h> /* FILE */
#include "Object.h" /* Stepstone Object.h assumes #import */
#endif
#include <set.h>
#include <ocstring.h>
#include "util.h"
#include "symbol.h"
#include "selector.h"
#include "node.h"
#include "def.h"
#include "propdef.h"
#include "stmt.h"
#include "compstmt.h"
#include "method.h"
#include "classdef.h"
#include "trlunit.h"
#include "options.h"
#include "type.h"
#include "expr.h"
#include "msgxpr.h"

@implementation PropertyDef 

- propname:aName
{
    name = aName;
    return self;
}

- proptype:aType
{
    type = aType;
    return self;
}

- classdef:aClass
{
    classdef = aClass;
    return self;
}

- synth
{
    if (!curclassdef)
    {
        fatal("property definition outside implementation");
    }
    else
    {
        id ivars = [curclassdef ivars];
        [ivars add:mkcomponentdef(nil, mklist(nil,type), mkdecl(name))];
        [curclassdef ivars:ivars];
        curdef = nil;
    }

    return self;
}

- gen
{
    id f, c;

    [classdef gen];		/* in case not yet emitted (must be done before blocks) */
    [super gen];			/* code for class references and blocks in this impl */

    return self;
}

@end
 

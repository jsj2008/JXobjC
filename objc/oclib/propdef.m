/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <assert.h>
#include <Object.h>
#include <Block.h>
#include <OCString.h>
#include <OrdCltn.h>
#include "util.h"
#include "symbol.h"
#include "node.h"
#include "def.h"
#include "decl.h"
#include "propdef.h"
#include "datadef.h"
#include "classdef.h"
#include "trlunit.h"
#include "type.h"

@implementation PropertyDef

- compdec:aDec
{
    compdec = aDec;
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
        fatal ("property definition outside implementation");
    }
    else
    {
        id ivars    = [curclassdef ivars];
        id decllist = [compdec decllist];
        id specs    = [compdec specs];
        int i, n;

        if (!ivars)
            ivars = [OrdCltn new];

        [ivars add:compdec];
        [curclassdef ivars:ivars];

        for (i = 0, n = [decllist size]; i < n; i++)
        {
            id var = [[decllist at:i] identifier];

            if (var)
            {
                id t = [Type new];
                id d = [decllist at:i];

                if (specs)
                {
                    [t specs:specs]; /* type filters out storage class */
                    [t decl:d];      /* type makes a -abstrdecl of it */
                }
                else
                {
                    [t addspec:s_int]; /* C default */
                    [t decl:d];
                }

                [curclassdef defcomp:var astype:t];
                [curclassdef
                    addpropmeth:mkpropsetmeth (compdec, t, var, [d ispointer])];
                [curclassdef
                    addpropmeth:mkpropgetmeth (compdec, t, var, [d ispointer])];
            }
        }

        [curclassdef synth];
        curdef = nil;
    }

    return self;
}

- gen
{
    [classdef gen]; /* in case not yet emitted (must be done before blocks) */
    [super gen];    /* code for class references and blocks in this impl */

    return self;
}

@end

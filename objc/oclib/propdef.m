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
#include "compdef.h"

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
        OrdCltn * compDefs = [OrdCltn new];
        id ivars           = [curclassdef ivars];
        id decllist        = [compdec decllist];
        id specs           = [compdec specs];
        id oldStruct       = curstruct;
        int i, n;

        curstruct = curclassdef;

        if (!ivars)
            ivars = [OrdCltn new];

        [curclassdef undefcomps];

        for (i = 0, n = [decllist size]; i < n; i++)
        {
            id var = [[decllist at:i] identifier];

            if (var)
            {
                ComponentDef * cDef = [ComponentDef new];
                id t                = [Type new];
                id d                = [decllist at:i];

                if (specs)
                {
                    [t specs:specs]; /* type filters out storage class */
                    [t decl:d];      /* type makes a -abstrdecl of it */
                    [cDef specs:specs];
                    [cDef add:d];
                }
                else
                {
                    [t addspec:s_int]; /* C default */
                    [t decl:d];
                    [cDef specs:[OrdCltn add:s_int]];
                    [cDef add:d];
                }

                [compDefs add:cDef];
            }
        }

        [compDefs elementsPerform:_cmd];

        [curclassdef ivars:[ivars addContentsOf:compDefs]];
        [curclassdef addivars];

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

                [curclassdef
                    addpropmeth:mkpropsetmeth (compdec, t, var, [d ispointer])];
                [curclassdef
                    addpropmeth:mkpropgetmeth (compdec, t, var, [d ispointer])];
            }
        }
        curstruct = oldStruct;
        curdef    = nil;
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

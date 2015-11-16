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
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <assert.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "Object.h"
#include "Block.h"
#include "OCString.h"
#include "OrdCltn.h"
#include "node.h"
#include "type.h"
#include "symbol.h"
#include "decl.h"
#include "arydecl.h"
#include "pointer.h"
#include "stardecl.h"
#include "options.h"
#include "structsp.h"
#include "enumsp.h"
#include "var.h"
#include "scalar.h"
#include "trlunit.h"

id t_unknown;
id t_void;
id t_char;
id t_bool;
id t_int;
id t_uns;
id t_long;
id t_double;
id t_str;
id t_sel;
id t_id;

typedef enum _BASIC_TYPESPECS
{
    T_NO,
    T_VOID,
    T_CHAR,
    T_BOOL,
    T_SHORT,
    T_INT,
    T_UNS,
    T_LONG,
    T_LONGLONG,
    T_FLOAT,
    T_DOUBLE,
    T_STR,
    T_SEL,
    T_ID,
} BASIC_TYPESPECS;

BASIC_TYPESPECS basicSpecForSpec (id spec)
{

    if ([spec isEqual:s_void])
        return T_VOID;
    else if ([spec isEqual:s_char])
        return T_CHAR;
    else if ([spec isEqual:s_bool])
        return T_BOOL;
    else if ([spec isEqual:s_int])
        return T_INT;
    else if ([spec isEqual:s_uns])
        return T_UNS;
    else if ([spec isEqual:s_long])
        return T_LONG;
    else if ([spec isEqual:s_double])
        return T_DOUBLE;
    else if ([spec isEqual:s_str])
        return T_STR;
    else if ([spec isEqual:s_sel])
        return T_SEL;
    else if ([spec isEqual:s_id])
        return T_ID;
    return T_NO;
}

@implementation Type

+ commontypes
{
    if (!t_unknown)
    {
        t_unknown = [Type new];
        t_void    = [[Type new] addspec:s_void];
        t_char    = [[Type new] addspec:s_char];
        t_bool    = [[Type new] addspec:s_bool];
        t_int     = [[Type new] addspec:s_int];
        t_uns     = [[Type new] addspec:s_uns];
        t_long    = [[Type new] addspec:s_long];
        t_double  = [[Type new] addspec:s_double];
        t_str     = [[Type new] addspec:s_str];
        t_sel     = [[Type new] addspec:s_sel];
        t_id      = [[Type new] addspec:s_id];
    }
    return self;
}

- specs { return specs; }

- decl { return decl; }

- abstrspecs:aList
{
    if (aList)
    {
        specs = aList;
    }
    else
    {
        specs = [OrdCltn new];
        [specs add:s_int]; /* C default */
    }
    return self;
}

- checkspec:s
{
    if ([s isKindOf:(id)[Symbol class]])
        return self;
    if ([s isKindOf:(id)[StructSpec class]])
        return self;
    if ([s isKindOf:(id)[EnumSpec class]])
        return self;
    fprintf (stderr, "%s\n", [s name]);
    return nil;
}

- (int)lineno
{
    if (specs)
    {
        int i, n = [specs size];
        for (i = 0; i < n; i++)
        {
            int no = [[specs at:i] lineno];
            if (no)
                return no;
        }
    }
    return 0;
}

- filename
{
    if (specs)
    {
        int i, n = [specs size];
        for (i = 0; i < n; i++)
        {
            id no = [[specs at:i] filename];
            if (no)
                return no;
        }
    }
    return nil;
}

- specs:aList
{
    if (aList)
    {
        int i, n;
        id typespecs = [OrdCltn new];

        for (i = 0, n = [aList size]; i < n; i++)
        {
            id s = [aList at:i];

            // assert([self checkspec:s]);
            /* filter out storageclass instances */
            if (![s isstorageclass] && ![s isgnuattrib])
                [typespecs add:s];
        }
        return [self abstrspecs:typespecs];
    }
    else
    {
        return [self addspec:s_int]; /* C default */
    }
}

- addspec:aSpec
{
    if (!specs)
        specs = [OrdCltn new];
    if (aSpec)
    {
        assert ([self checkspec:aSpec]);
        assert (![aSpec isstorageclass]);
        [specs add:aSpec];
    }
    return self;
}

- abstrdecl:aDecl
{
    decl = aDecl;
    return self;
}

- decl:aDecl { return [self abstrdecl:(aDecl) ? [aDecl abstrdecl] : nil]; }

- encode
{
    id result = [String new];
    id d      = decl;
    // clang-format off
    id p = [decl isKindOf:Pointer] ? decl
         : [decl isKindOf:StarDecl] ? (d = [decl decl], [decl pointer])
         : /*_*/ nil;
    // clang-format on
    short ptrCount, i, n;
    BOOL unsignedMod = NO, array = NO;

    printf ("d: %s, p = %s\n", [d str], [p str]);

    if ([d isKindOf:ArrayDecl])
        array = YES;

    if (array)
        [result sprintf:"[%d", [[d expr] asInt]];

    for (ptrCount = 0; ptrCount < [p numpointers]; ptrCount++)
        [result concatSTR:"^"];

    for (i = 0, n = [specs size]; i < n; i++)
    {
        id each = [specs at:i];
        printf ("Each: %s\n", [each str]);

        if ([each isKindOf:Symbol])
        {
            if (basicSpecForSpec (each) == T_UNS)
            {
                unsignedMod = YES;
                continue;
            }

            switch (basicSpecForSpec (each))
            {
            case T_VOID: [result concatSTR:"v"]; break;
            case T_CHAR: [result concatSTR:"c"]; break;
            case T_SHORT: [result concatSTR:"s"]; break;
            case T_INT: [result concatSTR:"i"]; break;
            case T_LONG: [result concatSTR:"l"]; break;
            case T_LONGLONG: [result concatSTR:"q"]; break;
            case T_FLOAT: [result concatSTR:"f"]; break;
            case T_DOUBLE: [result concatSTR:"d"]; break;
            case T_STR: [result concatSTR:"*"]; break;
            case T_ID: [result concatSTR:"@"]; break;
            case T_SEL: [result concatSTR:":"]; break;
            }

            if (unsignedMod)
            {
                short endLoc = [result size] - 1;
                [result charAt:endLoc put:toupper ([result charAt:endLoc])];
            }
        }
    }

    if (array)
        [result concatSTR:"]"];

    printf ("Result: <%s>\n", [result str]);

    return self;
}

- (BOOL)haslistinit { return haslistinit; }

- (BOOL)isstatic { return isstatic; }

- (BOOL)isextern { return isextern; }

- (BOOL)definesocu { return !isstatic; }

- isstatic:(BOOL)flag
{
    isstatic = flag;
    return self;
}

- isextern:(BOOL)flag
{
    isextern = flag;
    return self;
}

- haslistinit:(BOOL)flag
{
    haslistinit = flag;
    return self;
}

- max:aType
{
    if (self == t_unknown || aType == t_unknown)
        return t_unknown;
    return self;
}

- (uintptr_t)hash
{
    unsigned h = 0;

    if (specs)
    {
        int i, n;

        h = (n = [specs size]);
        for (i = 0; i < n; i++)
            h = (h << 1) ^ ([[specs at:i] hash]);
    }
    if (decl)
        h ^= [decl hash];
    return h;
}

- (BOOL)isEqual:x
{
    if (self == x)
    {
        return YES;
    }
    else
    {
        id y, z;

        y = [x specs];
        if (specs && y && ![specs isEqual:y])
            return NO;
        if ((!specs || !y) && specs != y)
            return NO;
        z = [x decl];
        if (decl && z && ![decl isEqual:z])
            return NO;
        if ((!decl || !z) && decl != z)
            return NO;
        return YES;
    }
}

- (BOOL)isvoid
{
    if (self == t_void)
        return YES;
    return decl == nil && [specs size] == 1 && [[specs at:0] isvoid];
}

- (BOOL)isid
{
    if (self == t_id)
        return YES;
    else if ([self isrefcounted])
        return YES;
    else
        return decl == nil && [specs size] == 1 && [[specs at:0] isid];
}

- (BOOL)isrefcounted
{
    BOOL isobj = NO, isvolatile = NO;
    int n;

    if (self == t_id)
    {
        return YES;
    }

    [specs do:
           { : each |
               if ([trlunit lookupclass:[String str:[each str]]])
                   isobj = YES;
               if ([each isvolatile])
                   isvolatile = YES;
           }];

    if (isvolatile)
        return NO;
    if (isobj && decl && [decl isKindOf:Pointer] && ![decl pointer])
        return YES;
    if (decl == nil && (n = [specs size]) > 0)
        return [[specs at:n - 1] isrefcounted];

    return NO;
}

- (BOOL)isscalartype
{
    /* same as canforward, except for structs */
    if ([decl ispointer])
    {
        return YES;
    }
    else
    {
        if (decl == nil || [decl isscalartype])
        {
            int i, n;

            /* anything that is defined as something that is scalar */
            for (i = 0, n = [specs size]; i < n; i++)
            {
                id sp = [specs at:i];

                if ([sp isstorageclass])
                    continue;
                if (![sp isscalartype])
                    return NO;
            }
            return YES;
        }
        else
        {
            return NO;
        }
    }
}

- (BOOL)canforward
{
    if ([decl ispointer])
    {
        return YES;
    }
    else
    {
        if (decl == nil || [decl canforward])
        {
            int i, n;

            /* anything that is defined as something that can be forwarded */
            for (i = 0, n = [specs size]; i < n; i++)
            {
                id sp = [specs at:i];

                if ([sp isstorageclass])
                    continue;
                if (![sp canforward])
                    return NO;
            }
            return YES;
        }
        else
        {
            return NO;
        }
    }
}

- (BOOL)isselptr
{
    if ([decl ispointer])
    {
        return YES;
    }
    else
    {
        if (decl == nil)
        {
            int i, n;

            /* anything that is defined as a pointer */
            for (i = 0, n = [specs size]; i < n; i++)
            {
                id sp = [specs at:i];

                if ([sp isstorageclass])
                    continue;
                if (![sp isselptr])
                    return NO;
            }
            return YES;
        }
        else
        {
            return NO;
        }
    }
}

- synth { return self; }

- gen
{
    [self encode];

    if (specs)
        [specs elementsPerform:@selector (gen)];
    if (decl)
        decl = [decl gen];
    return self;
}

- genabstrtype { return [self gendef:nil]; }

- gendef:sym
{
    [self encode];
    o_nolinetags++;
    if (specs)
        [specs elementsPerform:@selector (gen)];
    if (decl)
    {
        [decl gendef:sym];
    }
    else
    {
        if (sym)
            [sym gen];
    }
    o_nolinetags--;
    return self;
}

- dot:sym
{
    if (decl)
        return nil;
    else if ([specs size] != 1)
    {
        id stsp;
        [specs do:
               { :each | if ([each isKindOf:StructSpec]) stsp = each;
               }];
        return [stsp dot:sym];
    }
    else
        return [[specs at:0] dot:sym];
}

- star
{
    if (decl == nil && [specs size] == 1)
        return [[specs at:0] star];
    if (decl == nil && [specs size] != 1)
        return nil;
    return [[self copy] abstrdecl:[decl star]];
}

- ampersand
{
    id s, p;

    p = [Pointer new];
    s = [[[StarDecl new] pointer:p] decl:decl];
    return [[self copy] abstrdecl:s];
}

- funcall
{
    if (decl == nil && [specs size] == 1)
        return [[specs at:0] funcall];
    if (decl == nil && [specs size] != 1)
        return nil;
    return [[self copy] abstrdecl:[decl funcall]];
}

- zero
{
    if ([self isEqual:t_id])
        return nil;
    if ([self isEqual:t_str])
        return [[Scalar new] u_str:NULL];
    if ([decl isKindOf:(id)[ArrayDecl class]] && [specs size] == 1)
    {
        id s;
        int n = [[decl expr] asInt];
        s     = [Symbol new:n];
        return [[Scalar new] u_str:[s strCopy]];
    }
    if (decl == nil && [specs size] == 1)
    {
        return [[specs at:0] zero];
    }
    return nil;
}

- peekAt:(char *)ptr
{
    if (decl == nil && [specs size] == 1)
    {
        return [[specs at:0] peekAt:ptr];
    }
    else
    {
        [self notImplemented:_cmd];
        return 0;
    }
}

- poke:v at:(char *)ptr
{
    if (decl == nil && [specs size] == 1)
    {
        return [[specs at:0] poke:v at:ptr];
    }
    else
    {
        [self notImplemented:_cmd];
        return 0;
    }
}

- (int)bytesize
{
    if (decl == nil && [specs size] == 1)
    {
        return [[specs at:0] bytesize];
    }
    else
    {
        [self notImplemented:_cmd];
        return 0;
    }
}

@end

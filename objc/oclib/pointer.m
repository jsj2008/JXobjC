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
#include "node.h"
#include "decl.h"
#include "pointer.h"
#include "OCString.h"
#include "Block.h"

@implementation Pointer

- pointer { return pointer; }

- (int)numpointers
{
    id e, p;
    int h = 1;

    for (e = self; (p = [e pointer]); e = p)
        h++;
    return h;
}

- abstrdecl { return self; }

- (uintptr_t)hash { return [self numpointers]; }

- (BOOL)isEqual:x { return [self numpointers] == [x numpointers]; }

- (BOOL)ispointer { return YES; }

- (BOOL)canforward { return YES; }

- (BOOL)isscalartype { return YES; }

- specs:aList
{
    specs = aList;
    return self;
}

- hide:x rename:y { return self; }

- pointer:aDecl
{
    if (![aDecl isKindOf:(id)isa])
    {
        /* this should not be the case */
    }
    pointer = aDecl;
    return self;
}

- star
{
    if (pointer)
    {
        return [[self copy] pointer:[pointer star]];
    }
    else
    {
        return nil;
    }
}

- identifier { return anident; }
- identifier:anIdentifier
{
    anident = anIdentifier;
    return self;
}

- gen
{
    gc ('*');
    if (specs)
        [specs elementsPerform:@selector (gen)];
    if (pointer)
        [pointer gen];
    return self;
}

- gendef:sym
{
    gc ('*');
    if (specs)
        [specs elementsPerform:@selector (gen)];
    if (pointer)
    {
        [pointer gendef:sym];
    }
    else
    {
        if (anident)
            [anident gen];
        else if (sym)
            [sym gen];
    }
    return self;
}

- (String *)asDefFor:sym
{
    String * aType = [String str:"*"];

    [specs do:{ : each | [aType concat:each]}];
    if (pointer)
    {
        [aType concat:[pointer asDefFor:nil]];
    }
    else
    {
        if (anident)
            [aType concat:anident];
        else if (sym)
            [aType concat:sym];
    }
    return aType;
}

- synth { return self; }

- st80 { return self; }

@end

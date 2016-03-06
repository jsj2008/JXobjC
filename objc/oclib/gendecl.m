/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include <stdlib.h>
#include <assert.h>
#include "Object.h"
#include "MutableString.h"
#include "node.h"
#include "gendecl.h"

@implementation GenericDecl

- star
{
    if (decl)
    {
        return [[self copy] decl:[decl star]];
    }
    else
    {
        return nil;
    }
}

- abstrdecl
{
    if (decl)
    {
        id x = [decl abstrdecl];

        return [[self copy] decl:x];
    }
    else
    {
        return self;
    }
}

- identifier:aName
{
    [(id)decl identifier:aName];
    return self;
}

- decl:aDecl
{
    decl = aDecl;
    return self;
}

- decl { return decl; }

- identifier { return (decl) ? [decl identifier] : nil; }

- (BOOL)isfunproto { return (decl) ? [decl isfunproto] : NO; }

- (BOOL)ispointer { return YES; }

- (BOOL)canforward { return YES; }

- (BOOL)isscalartype { return YES; }

- hide:x rename:y
{
    if (decl)
        [decl hide:x rename:y];
    return self;
}
- gen
{
    if (decl)
        [decl gen];
    return self;
}

- gendef:sym
{
    if (decl)
        [decl gendef:sym];
    if (sym)
        [sym gen];
    return self;
}

- (String)asDefFor:sym
{
    MutableString aType = [String sprintf:"<%s>", [sym str]];

    if (decl)
    {
        [aType concat:[decl asDefFor:sym]];
    }
    return aType;
}

- synth
{
    if (decl)
        decl = [decl synth];
    return self;
}

- (uintptr_t)hash
{
    uintptr_t h = index;
    if (decl)
        h ^= [decl hash];
    return h;
}

- (BOOL)isEqual:x
{
    printf ("Test equality\n");
    if (self == x)
        return YES;
    if (![x isKindOf:GenericDecl])
        return NO;
    if ([x decl] == decl && [x index] == index)
        return YES;
    else
        return NO;
}

@end

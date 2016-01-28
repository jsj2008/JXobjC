/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "Object.h"
#include "Block.h"
#include "OCString.h"
#include "OrdCltn.h"
#include "Set.h"
#include "Dictionary.h"
#include "node.h"
#include "symbol.h"
#include "selector.h"
#include "classdef.h"
#include "trlunit.h"
#include "options.h"
#include "decl.h"
#include "pointer.h"
#include "def.h"
#include "methdef.h"
#include "protodef.h"

@implementation ProtoDef

- (char *)classname { return "Prototype"; }

- (int)compare:b
{
    int c;
    char *s1, *s2;
    s1 = [[self protoname] str];
    s2 = [[b protoname] str];
    c  = strcmp (s1, s2);
    return c;
}

- addMethod:(Method *)aMeth
{
    if (!methsForSels)
        methsForSels = [Dictionary new];
    [methsForSels atKey:[aMeth selector] put:aMeth];
    return self;
}

- addclssel:method
{
    if (!clssels)
        clssels = [OrdCltn new];
    [clssels add:method];
    assert ([method isKindOf:(id)[Selector class]]);
    return self;
}

- addnstsel:method
{
    if (!nstsels)
        nstsels = [OrdCltn new];
    [nstsels add:method];
    assert ([method isKindOf:(id)[Selector class]]);
    return self;
}

- clssels { return clssels; }

- nstsels { return nstsels; }

- synth { return self; }
- gen { return self; }

@end

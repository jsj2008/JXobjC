/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "config.h"
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <stdio.h> /* FILE */
#include "Object.h"
#include "Block.h"
#include <ocstring.h>
#include <ordcltn.h>
#include <set.h>
#include <dictnary.h>
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

- (int)compare:b
{
    int c;
    char *s1, *s2;
    s1 = [[self protoname] str];
    s2 = [[b protoname] str];
    c  = strcmp (s1, s2);
    return c;
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
- gen { return self; }

@end

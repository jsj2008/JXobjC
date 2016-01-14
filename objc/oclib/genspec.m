/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "OCString.h"
#include "OrdCltn.h"
#include "genspec.h"

@implementation GenericSpec

- (uintptr_t)hash { return [types hash] ?: 101; }

- (STR)str { return "Generic Specialisator"; }

- (BOOL)isEqual:x
{
    if (![x isKindOf:GenericSpec])
        return NO;
    return types ? [types isEqual:[x types]] : YES;
}

- synth
{
    //[types elementsPerform:print];
    [types elementsPerform:_cmd];
    return self;
}

- gen { return self; }

@end
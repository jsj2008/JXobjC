/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "MutableString.h"
#include "OrdCltn.h"
#include "sequence.h"
#include "type.h"
#include "genspec.h"

@implementation GenericSpec

- (uintptr_t)hash { return [types hash] ?: 101; }

- (STR)str
{
    Type * aType;
    Sequence * typeSeq   = [types eachElement];
    MutableString * desc = [@"<" mutableCopy];

    while ((aType = [typeSeq next]))
    {
        [desc concat:[aType asDefFor:nil]];
        if ([typeSeq peek])
            [desc concat:@", "];
    }

    return [[desc concat:@">"] str];
}

- (BOOL)isid { return YES; }

- (BOOL)isrefcounted { return YES; }

- (BOOL)canforward { return YES; }

- (BOOL)isEqual:x
{
    if (![x isKindOf:GenericSpec])
        return NO;
    return types ? [types isEqual:[x types]] : YES;
}

- synth
{
    [types elementsPerform:_cmd];
    return self;
}

- gen { return self; }

@end
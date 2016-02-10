/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "Dictionary.h"

@implementation Dictionary (KVC) <Tkey, Tval>

- valueForKey:key { return [self atKey:key] ?: [super valueForKey:key]; }

- (void)setValue:value forKey:key
{
    if ([self includesKey:key])
        [self atKey:key put:value];
    else
        [super setValue:value forKey:key];
}

@end
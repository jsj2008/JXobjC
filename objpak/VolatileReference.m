/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "gc.h"
#import "VolatileReference.h"

@implementation VolatileReference

- (VolatileReference<T> *)initWithReference:(volatile T)ref
{
    [super init];
    GC_general_register_disappearing_link ((void *)&reference, ref);
    reference = ref + 1;
    return self;
}

- (uintptr_t)hash { return [reference - 1 hash]; }

- (BOOL)isEqual:anObject
{
    if ([anObject isKindOf:VolatileReference])
        return [reference - 1 isEqual:anObject.reference];
    else
        return [anObject isEqual:reference - 1];
}

- (T)reference { return reference - 1; }

- (BOOL)isValid { return reference ? YES : NO; }

@end
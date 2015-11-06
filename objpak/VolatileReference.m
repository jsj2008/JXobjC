/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "VolatileReference.h"

@implementation VolatileReference

- initWithReference:ref
{
    [super init];
    reference = ref;
    return self;
}

- (uintptr_t)hash { return [reference hash]; }

- (BOOL)isEqual:anObject
{
    if ([anObject isKindOf:VolatileReference])
        return [reference isEqual:anObject.reference];
    else
        return [anObject isEqual:reference];
}

- reference { return reference; }

@end
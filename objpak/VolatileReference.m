/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "VolatileReference.h"

@implementation VolatileReference

- initWithReference:ref
{
    [super init];
    reference = ref;
    return self;
}

- (unsigned)hash { return [reference hash]; }

- (BOOL)isEqual:anObject { return [reference isEqual:anObject]; }

- reference { return reference; }

@end
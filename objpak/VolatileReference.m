/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <gc.h>
#import "objcrt.h"
#import "Exceptn.h"
#import "VolatileReference.h"

@implementation VolatileReference

- (VolatileReference<T> *)newWithReference:(volatile T)ref
{
    return [[self alloc] initWithReference:ref];
}

- (VolatileReference<T> *)initWithReference:(volatile T)ref
{
    if (reference)
        [Exception signal:"VolatileReferences may not be initialised twice."];
    [super init];
    reference = OC_MallocAtomic (sizeof (id) * 2);
    GC_general_register_disappearing_link ((void *)reference, ref);
    reference[0] = ref;
    reference[1] = ref;
    return self;
}

- (uintptr_t)hash { return [reference[0] hash]; }

- (BOOL)isEqual:anObject
{
    if ([anObject isKindOf:VolatileReference])
    {
        if (reference[0] && anObject.reference)
            return [reference[0] isEqual:anObject.reference];
        else
            return reference[1] == anObject.originalReference;
    }
    else
        return [anObject isEqual:reference[0]];
}

- (char *)str { return [reference[0] str]; }

- (T)reference { return reference[0]; }

- (T)originalReference { return reference[1]; }

- (BOOL)isValid { return reference ? YES : NO; }

@end
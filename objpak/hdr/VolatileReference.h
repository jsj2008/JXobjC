/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface VolatileReference : Object
{
    volatile id reference;
}

- initWithReference:ref;
- reference;

@end
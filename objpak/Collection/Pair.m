/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Pair.h"

@implementation Pair

- ARC_dealloc
{
    first  = nil;
    second = nil;
    return [super ARC_dealloc];
}

@end
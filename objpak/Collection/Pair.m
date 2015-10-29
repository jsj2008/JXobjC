/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Pair.h"

@implementation Pair

+ (Pair *)pairWithFirst:one second:two
{
    return [[self alloc] initWithFirst:one second:two];
}

- initWithFirst:one second:two
{
    [super init];
    first  = one;
    second = two;
    return self;
}

- ARC_dealloc
{
    first  = nil;
    second = nil;
    return [super ARC_dealloc];
}

@end
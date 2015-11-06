/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Pair.h"
#import "OrdCltn.h"
#import "VolatileReference.h"

@implementation Pair

+ (Pair *)pairWithFirst:one second:two
{
    return [[self alloc] initWithFirst:one second:two];
}

+ (Pair *)pairWithVolatileFirst:one volatileSecond:two
{
    return [[self alloc]
        initWithFirst:[[VolatileReference alloc] initWithReference:one]
               second:[[VolatileReference alloc] initWithReference:two]];
}

+ (Pair *)pairWithVolatileFirst:one second:two
{
    return [[self alloc]
        initWithFirst:[[VolatileReference alloc] initWithReference:one]
               second:two];
}

- (uintptr_t)hash { return [first hash] % ([second hash] ?: 0x1234); }

- (BOOL)isEqual:anObject
{
    BOOL result;
    result = ([first isEqual:anObject.first] || first == anObject.first) &&
             ([second isEqual:anObject.second] || second == anObject.second);
    return result;
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

- free
{
    if ([first respondsTo:@selector (freeContents)])
        [first freeContents];
    if ([second respondsTo:@selector (freeContents)])
        [second freeContents];
    [first free];
    [second free];
    return [super free];
}

@end
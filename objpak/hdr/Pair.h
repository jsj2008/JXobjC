/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface Pair : Object

@property id first, second;
@property volatile char comparator;

+ (Pair *)pairWithFirst:one second:two;
+ (Pair *)pairWithVolatileFirst:one volatileSecond:two;
+ (Pair *)pairWithVolatileFirst:one second:two;
- initWithFirst:one second:two;

@end
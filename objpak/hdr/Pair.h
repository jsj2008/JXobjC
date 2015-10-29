/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface Pair : Object

@property id first, second;

+ (Pair *)pairWithFirst:one second:two;
- initWithFirst:one second:two;

@end
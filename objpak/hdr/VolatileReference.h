/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface VolatileReference : Object

@property volatile id referredObject;

@end
/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "node.h"

#ifndef GENSPEC_H_
#define GENSPEC_H_

@class OrdCltn;

@interface GenericSpec : Node

/* Ordered from 0 upwards, the OrdCltn here stores a Type * for each generic
 * argument (i.e. <arg0, arg1, ... arg99). */
@property OrdCltn * types;

- synth;
- gen;

@end

#endif
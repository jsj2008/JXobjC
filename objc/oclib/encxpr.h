/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#ifndef ENCXPR__H__
#define ENCXPR__H__

#include "OCString.h"
#include "unyxpr.h"
#include "type.h"

@interface Encode : UnaryExpr

@property Type typeForEncoding;

+ new;
- typesynth;

@end

#endif

/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#ifndef PRDOTXPR__H__
#define PRDOTXPR__H__

#include "msgxpr.h"

@interface DotPropertyExpr : MesgExpr

@property BOOL replaced;
@property id setExpr;
@property id propSym;

- forcegen;

@end

#endif
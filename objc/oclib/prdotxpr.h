/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "msgxpr.h"

@interface DotPropertyExpr : MesgExpr

@property BOOL replaced;
@property id setExpr;
@property id propSym;

- forcegen;

@end
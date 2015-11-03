/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <ctype.h>

#import "OCString.h"
#import "prdotxpr.h"
#import "identxpr.h"
#import "util.h"

@implementation DotPropertyExpr

- synth
{
    id arg, args;

    if (!setExpr)
        msg = mkmethproto (nil, mkidentexpr (propSym), nil, NO);
    else
    {
        id selnam = [String sprintf:"set%s", [propSym str]];

        [selnam charAt:3 put:toupper ([selnam charAt:3])];

        arg         = mkkeywarg ([IdentifierExpr str:[selnam str]], setExpr);
        args        = mklist (nil, arg);
        msg         = mkmethproto (nil, nil, args, NO);
        methodfound = NO;
        method      = nil;
        sel         = nil;
    }

    return [super synth];
}

- gen
{
    if (!replaced)
        return [self forcegen];
    else
        return self;
}

- forcegen { return [super gen]; }

@end

/*
mkkeywarg ([IdentifierExpr str:@selector (str)],
                        [string deleteFrom:0 to:0]);
    id args = mklist (nil, arg);
    id msg  = mkmethproto (nil, nil, args, NO);*/
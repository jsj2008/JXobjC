/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "prdotxpr.h"
#import "util.h"

@implementation DotPropertyExpr

- synth
{
    id arg, args, mesg;

    if (!setExpr)
        mesg = mkmethproto (nil, mkidentexpr (propSym), nil, NO);

    msg = mesg;
    return [super synth];
}

@end

/*
mkkeywarg ([IdentifierExpr str:@selector (str)],
                        [string deleteFrom:0 to:0]);
    id args = mklist (nil, arg);
    id msg  = mkmethproto (nil, nil, args, NO);*/
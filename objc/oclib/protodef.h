/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#ifndef PROTODEF_H_
#define PROTODEF_H_

#include "node.h"

@interface ProtoDef : Node
{
    id clssels;
    id nstsels;
    int offset;
}

@property id protoname;
@property Dictionary generics;
@property Dictionary methsForSels;

- (char *)classname;
- (int)compare:c;

- addMethod:(Method)aMeth;

- addclssel:method;
- addnstsel:method;

- clssels;
- nstsels;

- synth;
- gen;

@end

#endif

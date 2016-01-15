/* Copyright (c) 2015 D. Mackay. All rights reserved. */

@interface ProtoDef : Node
{
    id clssels;
    id nstsels;
    int offset;
}

@property id protoname;
@property Dictionary * generics;

- (int)compare:c;

- addclssel:method;
- addnstsel:method;

- clssels;
- nstsels;

- synth;
- gen;

@end

/* Copyright (c) 2015 D. Mackay. All rights reserved. */

@interface PropertyDef : Def
{
    id unit;
    id compdec;
    id classdef;
}

@property BOOL isCopy, isNonAtomic;

- classdef:aClass;
- compdec:aDec;

- synth;
- gen;

@end

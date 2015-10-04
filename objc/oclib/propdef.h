/* Copyright (c) 2015 D. Mackay. All rights reserved. */

@interface PropertyDef : Def
{
    id unit;
    id compdec;
    id classdef;
}

- classdef:aClass;
- compdec:aDec;

- synth;
- gen;

@end

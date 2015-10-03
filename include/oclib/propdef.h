/*
 * Copyright (c) 2015 D Mackay
 */

@interface PropDef : Def
{
    id unit;
    char * type;
    char * name;
    id classdef;
}

- classdef:aClass;
- (char *)proptype;
- (char *)propname;

- synth;
- gen;

@end

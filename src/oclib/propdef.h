/*
 * Copyright (c) 2015 D Mackay
 */

@interface PropertyDef : Def
{
  id unit;
  id type;
  id name;
  id classdef;
}

- classdef:aClass;
- proptype:aType;
- propname:aName;

- synth;
- gen;

@end

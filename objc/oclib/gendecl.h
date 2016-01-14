/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#pragma once

#include "decl.h"
#include "symbol.h"

@interface GenericDecl : Decl
{
    Decl * decl;
}

@property Symbol * sym;
@property int index;

- decl:aDecl;
- gen;

@end

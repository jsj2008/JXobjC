/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "decl.h"
#include "symbol.h"

#ifndef GENDECL_H_
#define GENDECL_H_

@interface GenericDecl : Decl
{
    Decl * decl;
}

@property Symbol * sym;
@property int index;

- decl:aDecl;
- gen;

@end

#endif
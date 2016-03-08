/*
 * Copyright (c) 1998 David Stes.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "node.h"

extern id t_unknown;
extern id t_void;
extern id t_char;
extern id t_bool;
extern id t_short;
extern id t_int;
extern id t_long;
extern id t_uns;
extern id t_double;
extern id t_str;
extern id t_sel;
extern id t_id;

#ifndef TYPE__H__
#define TYPE__H__

@class ClassDef, Decl, GenericSpec, GenericDecl, OrdCltn, String, Symbol;

@interface Type : Node
{
    OrdCltn specs;
    Decl decl;
    BOOL isstatic;
    BOOL isextern;
    BOOL haslistinit;
}

@property BOOL isobject;

+ commontypes;
- (OrdCltn)specs;
- specs:(OrdCltn)aList;
- abstrspecs:(OrdCltn)aList;
- addspec:aSpec;
- (Decl)decl;
- decl:(Decl)aDecl;
- abstrdecl:(Decl)aDecl;
- (BOOL)isstatic;
- (BOOL)isextern;
- (BOOL)haslistinit;
- (BOOL)definesocu;
- isstatic:(BOOL)flag;
- isextern:(BOOL)flag;
- haslistinit:(BOOL)flag;
- gen;
- gendef:sym;
- genabstrtype;

- (String)asDefFor:sym;

- max:aType;
- (uintptr_t)hash;
- (BOOL)isEqual:x;
- filename;
- (int)lineno;

- (BOOL)isid;
- (BOOL)isRealId;
- (BOOL)isrefcounted;
- (BOOL)isNamedClass;
- (BOOL)isvoid;
- (BOOL)canforward;
- (BOOL)isscalartype;
- (BOOL)isselptr;
- (BOOL)isGenSpec;
- (BOOL)isTypeEqual:x;

- (ClassDef)getClass;
- (GenericSpec)getGenSpec;
- (Type)genDeclForClass:aClass;

- (String)encode;

- (Type)dot:(Symbol)sym;
- (Type)star;
- (Type)funcall;
- (Type)ampersand;

@end

#endif

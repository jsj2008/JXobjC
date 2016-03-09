/*
 * Copyright (c) 1998,2000 David Stes.
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
/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef CLASSDEF_H_
#define CLASSDEF_H_

extern id curclassdef;
extern id curstruct;

@class ClassDef, ComponentDef, Decl, Expr, Method, MethodDef, OrdCltn, Set,
    Selector, StructSpec, TranslationUnit, Type;

#include "Dictionary.h"
#include "node.h"
#include "symbol.h"

@interface ClassDef : Node
{
    TranslationUnit unit;
    StructSpec privStruct;
    Type selftype;
    Symbol classname;

    char * otbtypename;
    char * privtypename;
    char * shartypename;
    char * clsdisptblname;
    char * nstdisptblname;
    char * globfunname;
    char * c_classname;
    char * _classname;
    char * _classfunname;
    char * _superfunname;
    char * _m_classname;
    char * _m_classfunname;
    char * _m_superfunname;

    ClassDef rootc;
    ClassDef superc;
    Symbol supername;
    OrdCltn<ClassDef> categories;
    OrdCltn<ComponentDef> ivars, cvars;

    BOOL emitintf;
    BOOL emitimpl;
    BOOL emitfwddecl;
    BOOL isimpl; /* being implemented in this trlunit */
    BOOL iscategory;

    Set<Selector> clsdispsels,
        nstdispsels; /* selectors *implemented* (overridden) */
    OrdCltn<MethodDef>
        clsdisptbl; /* class methods *implemented* (overridden) */
    OrdCltn<MethodDef>
        nstdisptbl; /* instance methods *implemented* (overridden) */

    OrdCltn<Selector> clssels; /* selectors of class methods prototyped */
    OrdCltn<Selector> nstsels; /* selectors of instance methods prototyped */
    Dictionary methsForSels;
    Dictionary compdic, ivardic, cvardic;
    OrdCltn<Symbol> compnames, ivarnames, cvarnames;
    OrdCltn<Type> comptypes, ivartypes, cvartypes;
    OrdCltn<Symbol> delegates;
    Set<Symbol> allivarnames, allcvarnames;
    MethodDef fileinmethod, fileoutmethod;
    MethodDef decrefsmethod, increfsmethod;
    OrdCltn<MethodDef> propmeths;
    long offset;
}

@property Dictionary generics;

- (int)compare:c;

- selftype;
- forceimpl;
- (BOOL)isimpl;
- iscategory:(BOOL)isit;
- warnpending;
- (char *)classname;
- (char *)shartypename;
- (char *)privtypename;
- (char *)otbtypename;
- (char *)globfunname;
- (char *)c_classname;
- (char *)_classname;
- (char *)_m_classname;
- (char *)_classfunname;
- (char *)_m_classfunname;
- (char *)_superfunname;
- (char *)_m_superfunname;
- classname:(Symbol)sym;
- (char *)supername;
- supername:sym;
- superclassdef;
- checksupername:sym;
- rootclassdef;
- (char *)rootname;
- ivars;
- ivars:aList;
- checkivars:aList;
- cvars;
- cvars:aList;
- clssels;
- nstsels;
- checkcvars:aList;
- addclsdisp:method;
- addnstdisp:method;

- warnimplnotfound;
- addclssel:method;
- addnstsel:method;

- (int)numidivars;
- synthfilermethods;
- synthrefcntmethods;
- synthpropmethods;

- addMethod:(Method)aMeth;

- (BOOL)forcegenintf;

- gen;
- genivars;
- gencvars;
- genintf;
- genimpl;
- genfwddecl;
- genshartype;
- gensuper;
- genmetasuper;
- genclassref;

/* Should this be folded into methodForSelector ? */
- lookupSelector:(Selector)aSel forDecl:(Decl)aDecl;
- (Method)methodForSelector:(Selector)aSel forDecl:(Decl)aDecl;
- lookupivar:sym;
- lookupcvar:sym;
- (BOOL)isivar:sym;
- (BOOL)iscvar:sym;
- defcomp:sym astype:t;
- undefcomps;
- use;

- addpropmeth:propmeth;
- addivars;
- propmeths;

- (BOOL)checkAssign:(ClassDef)aClass;
- (BOOL)isRelated:(ClassDef)aClass;

@end

@interface ClassDef (NFI)

/*! Retrieves the index of the iVar corresponding to a specified Symbol. Returns
 * -1 if no such iVar is found. */
- (int)indexOfIVar:(Symbol)aSym;
- (int)indexOfCVar:(Symbol)aSym;

/* Declares the offset tables in the code tree.
 * Does not generate actual delarations. */
- declareOffsetTables;

/* Retrieves a fast accessor for the specified iVar. */
- (Expr)fastAddressForIVar:(Symbol)aVar;
- (Expr)fastAddressForCVar:(Symbol)aVar;

/* Internal use by ClassDef: */
- genVarOffsetVars_isForFactory:(BOOL)isFactory className:(Symbol)aName;
- genVarOffsetsArray_isForFactory:(BOOL)isFactory className:(Symbol)aName;

@end

#endif

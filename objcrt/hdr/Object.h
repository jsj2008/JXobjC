/*
 * Portable Object Compiler (c) 1997,98,99,2000,03,14.  All Rights Reserved.
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

#ifndef __OBJECT_H__
#define __OBJECT_H__

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "objcrt.h"
#include "RtObject.h"

#define __objcrt_revision__ "4.5"

#ifdef _XtIntrinsic_h
#define Object OCObject /* remap Object class - cant use Xt Object */
#endif

/*!
 Object is the primary root class in JX Objective-C.
 It provides objects inheriting from it - which most do - with a reasonable
 set of behaviour. Other root classes used by the user may include
 @link Proxy @/link
*/
@interface Object : RtObject
- class;
- superclass;
- superClass;
+ class;
+ superclass;
+ superClass;
- (STR)name;
+ (STR)name;
- findClass:(STR)name;
- (SEL)findSel:(STR)name;
- (SEL)selOfSTR:(STR)name;
- idOfSTR:(STR)aClassName;

- (uintptr_t)hash;
- (BOOL)isEqual:anObject;
- (STR)str;
- (unsigned)size;
+ (BOOL)isEqual:anObject;
- (BOOL)isSame:anObject;
- (BOOL)notEqual:anObject;
- (BOOL)notSame:anObject;
- (int)compare:anObject;
- (int)invertCompare:anObject;

- (BOOL)respondsTo:(SEL)aSelector;
- (BOOL)isMemberOf:aClass;
- (BOOL)isKindOf:aClass;

+ someInstance;
- nextInstance;
- become:other;

+ subclasses;
+ poseAs:superClass;
+ addMethodsTo:superClass;
+ subclass:(STR)name;
+ subclass:(STR)name:(int)ivars:(int)cvars;
+ load;
+ unload;
+ (BOOL)inheritsFrom:aClass;
+ (BOOL)isSubclassOf:aClass;

- subclassResponsibility;
- subclassResponsibility:(SEL)aSelector;
- notImplemented;
- notImplemented:(SEL)aSelector;
- shouldNotImplement;
- shouldNotImplement:(SEL)aSelector;
- shouldNotImplement:(SEL)aSelector from:superClass;
- error:(STR)format, ...;
- halt:message;

- perform:(SEL)aSelector;
- perform:(SEL)aSelector with:anObject;
- perform:(SEL)aSelector with:anObject with:otherObject;
- perform:(SEL)aSelector with:anObject with:otherObject with:thirdObj;

- print;
+ print;
- printLine;
- show;
- printOn:(IOD)anIOD;

+ (STR)objcrtRevision;

+ readFrom:(STR)aFileName;
- (BOOL)storeOn:(STR)aFileName;

- fileOutOn:aFiler;
+ fileInFrom:aFiler;
- fileInFrom:aFiler;
- fileOut:(void *)value type:(char)typeDesc;
- fileIn:(void *)value type:(char)typeDesc;
- awake;
- awakeFrom:aFiler;

/* private */
- new;
- initialize;
+ free;
+ ARC_dealloc;

- _lock;
- _unlock;

+ become:other;
- vsprintf:(STR)format:(OC_VA_LIST *)ap;
- str:(STR)s;
- ARC_dealloc;
- add:anObject;
- printToFile:(FILE *)aFile;
- fileOutIdsFor:aFiler;
- fileInIdsFrom:aFiler;
- fileOutIdsFor;
- fileInIdsFrom;
@end

#endif /* __OBJECT_H__ */

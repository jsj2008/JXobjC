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
#define myClass class

#ifdef _XtIntrinsic_h
#define Object OCObject /* remap Object class - cant use Xt Object */
#endif

/*!
 @class Object
 Object is the primary root class in JX Objective-C.
 It provides objects inheriting from it - which most do - with a reasonable
 set of behaviour.
 @seealso Proxy
 @indexgroup JX Runtime
 */
@interface Object : RtObject

/*! @group Comparison */

/*!
  Retrieve the unique hash of an object.
  @return The object's unique hash.
 */
- (uintptr_t)hash;

/*!
  Checks if two objects are equal.
  @param anObject The object to compare with.
  @return By default, YES if pointer addresses are equal; NO if not.
 */
- (BOOL)isEqual:anObject;

/*!
  Checks if two classes are the same.
  @param anObject The class to compare with.
  @return By default, YES if pointer addresses are equal; NO if not.
 */
+ (BOOL)isEqual:anObject;

/*!
  Checks if two objects are the same.
  @param anObject The object to compare with.
  @return YES if pointer addresses are equal; NO if not.
 */
- (BOOL)isSame:anObject;

- (BOOL)notEqual:anObject;
- (BOOL)notSame:anObject;
- (int)compare:anObject;
- (int)invertCompare:anObject;

/*! @group Introspection */

/*! Returns the class of the object. */
- myClass;

/*! Returns the superclass of the object. */
- superclass;
/*! Compatibility alias for @link superclass @/link. */
- superClass;

/*! Returns the class of a class. In fact, this always returns <em>self</em> by
    tradition. */
+ myClass;

/*! Returns the superclass of this class (its parent class). */
+ superclass;
/*! Compatibility alias for @link superclass @/link. */
+ superClass;

/*! Returns the name of this object. By default, returns the name of its
    class. */
- (STR)name;
/*! Returns the name of this class. */
+ (STR)name;

/*! Returns the class identified by an STR. If no such class exists, returns
    nil.
    @param name The STR containing a classes' name. */
- (id)findClass:(STR)name;

/*! Returns the SEL corresponding to an STR. If no SEL is found, returns NULL.
    @param name The SEL containing a selector string. */
- (SEL)findSel:(STR)name;

- (SEL)selOfSTR:(STR)name;
- (id)idOfSTR:(STR)aClassName;
/*! Returns the STR representation of an object. By default, returns the name
    of the object's class. */
- (STR)str;

/*! Returns the size of the object. */
- (unsigned)size;

/*! Checks if the object responds to a selector.
    @return YES if the object responds to the selector, NO if not.
    @param aSelector Which selector to test the object's response to. */
- (BOOL)respondsTo:(SEL)aSelector;

/*! Checks if the object is an instance of a class.
    @param aClass Which class to test the object's membership of.
    @return YES if the object is a direct instance of the class, NO if it an
    instance of a subclass or otherwise. */
- (BOOL)isMemberOf:aClass;

/*! Checks if the object is an instance of a kind of class.
    @param aClass Which class to test the object's belonging to.
    @return YES if the object is a direct or subclass instance of the class, NO
    if it is not. */
- (BOOL)isKindOf:aClass;

+ someInstance;
- nextInstance;
- become:other;

/*! @group Class dynamism */

/*! Returns an @link OrdCltn @/link of this class' subclasses. */
+ subclasses;

/*! Have this subclass substitute for a parent class.
    @param superClass The class to be substituted with this class. */
+ poseAs:superClass;

/*! Add this class' methods to a parent class.
    @param superClass The class to have this class' methods added to. */
+ addMethodsTo:superClass;

/*!
  Create a new subclass of this class.
  @param name The STR representing the newly-created subclass' name.
  @return A new subclass. Use @link load @/link to load it into the running
  programme.
 */
+ (id)subclass:(STR)name;

/*!
  Create a new subclass of this class.
  @param name An STR representing the newly-created subclass' name.
  @param ivars Count of additional instance variables to be added to the new
  subclass.
  @param cvars Count of additional factory variables to be added to the new
  subclass.
  @return A new subclass. Use @link load @/link to load it into the running
  programme.
 */
+ (id)subclass:(STR)name:(int)ivars:(int)cvars;

/*! Load this class into the running programme. */
+ load;
/*! Unload this class from the running programme. */
+ unload;

/*! Find out whether this class inherits from another class.
    @param aClass The class to test this classes' inheritance from.
    @return YES if class inherits from aClass, NO if not. */
+ (BOOL)inheritsFrom:aClass;

/*! Compatibility alias for @link inheritsFrom: @/link. */
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

/*! @group Dynamic messaging */

/*! Performs the given selector on this instance.
    @param aSelector The selector to perform. */
- (id)perform:(SEL)aSelector;
/*! Performs the given selector on this instance with a single <em>id</em>
    parameter.
    @param aSelector The selector to perform
    @param anObject The first parameter. */
- (id)perform:(SEL)aSelector with:anObject;
/*! Performs the given selector on this instance with two <em>id</em>
    parameters.
    @param aSelector The selector to perform.
    @param anObject The first parameter.
    @param otherObject The second parameter. */
- (id)perform:(SEL)aSelector with:anObject with:otherObject;
/*! Performs the given selector on this instance with three <em>id</em>
    parameters.
    @param aSelector The selector to perform.
    @param anObject The first parameter.
    @param otherObject The second parameter.
    @param thirdObj The third parameter. */
- (id)perform:(SEL)aSelector with:anObject with:otherObject with:thirdObj;

- (id)perform:(SEL)aSelector
         with:anObject
         with:otherObject
         with:thirdObj
         with:fourthObj;

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
- initialize;
+ free;
+ ARC_dealloc;

+ become:other;
- vsprintf:(STR)format:(OC_VA_LIST *)ap;
- str:(STR)s;
- add:anObject;
- printToFile:(FILE *)aFile;
- fileOutIdsFor:aFiler;
- fileInIdsFrom:aFiler;
- fileOutIdsFor;
- fileInIdsFrom;
/* KVO stub */
- (void)sendKVOForProperty:prop oldValue:oldVal newValue:newVal;
@end

#endif /* __OBJECT_H__ */

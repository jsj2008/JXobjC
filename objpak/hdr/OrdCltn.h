/*
 * Portable Object Compiler (c) 1997,98,99,2003.  All Rights Reserved.
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

#ifndef __OBJCLTN_H__
#define __OBJCLTN_H__

#include "cltn.h"

/* full name */
#define OrderedCollection OrdCltn

typedef struct objcol
{
    int count;
    int capacity;
    id * ptr;
} * objcol_t;

/*!
 @abstract An Ordered collection of objects.
 @discussion Stores objects in an ordered form similar to the C++ STL's Vector.
 Objects at any specified index may be retrieved, removed, or inserted. The
 index begins at 0 for the first object, and ends at
 <em>@link size @/link - 1</em> for the last.
 @indexgroup Collection
 */
@interface OrdCltn : Cltn
{
    struct objcol value;
}

/*! @group Instance management */
+ new;
+ new:(unsigned)n;
+ with:(int)nArgs, ...;
+ with:firstObject with:nextObject;
+ add:firstObject;
/*! Copies the OrdCltn. The objects themselves are not copied, only their
    identifiers, so the contents are 100% identical to the original OrdCltn. */
- copy;

/*! Copies the OrdCltn, sending a deepCopy message to each object contained. */
- deepCopy;
- emptyYourself;
- freeContents;
- free;

/*! @group Inquiry */

/*! Queries the OrdCltn, returning the number of objects stored in it. */
- (unsigned)size;

/*! Queries the OrdCltn on whether it is empty.
    @return YES if it is empty, NO if it is not. */
- (BOOL)isEmpty;

/*! Requests the offset of the last element.
    @return Offset of the last element if OrdCltn is not empty, -1 if it is. */
- (unsigned)lastOffset;
- eachElement;
- firstElement;
- lastElement;

- (BOOL)isEqual:aCltn;

- add:anObject;
- addFirst:newObject;
- addLast:newObject;
- addIfAbsent:anObject;
- addIfAbsentMatching:anObject;

- at:(unsigned)anOffset insert:anObject;
- insert:newObject after:oldObject;
- insert:newObject before:oldObject;

- after:anObject;
- before:anObject;
- at:(unsigned)anOffset;
- at:(unsigned)anOffset put:anObject;

- removeFirst;
- removeLast;
- removeAt:(unsigned)anOffset;
- removeAtIndex:(unsigned)anOffset;
- remove:oldObject;
- remove:oldObject ifAbsent:exceptionBlock;

- (BOOL)includesAllOf:aCltn;
- (BOOL)includesAnyOf:aCltn;

- addAll:aCltn;
- addContentsOf:aCltn;
- addContentsTo:aCltn;
- removeAll:aCltn;
- removeContentsFrom:aCltn;
- removeContentsOf:aCltn;

- intersection:bag;
- union:bag;
- difference:bag;

- asSet;
- asOrdCltn;

- detect:aBlock;
- detect:aBlock ifNone:noneBlock;
- select:testBlock;
- reject:testBlock;
- collect:transformBlock;
- (unsigned)count:aBlock;

- elementsPerform:(SEL)aSelector;
- elementsPerform:(SEL)aSelector with:anObject;
- elementsPerform:(SEL)aSelector with:anObject with:otherObject;
- elementsPerform:(SEL)aSelector with:anObject with:otherObject with:thirdObj;

/*! Calls a block with each object in the OrdCltn, passing in turn each object
    as the single parameter to the block.
    @param aBlock Block to be called with each object as its argument. */
- do:aBlock;

/*! Calls a block with each object in the OrdCltn, until a BOOL becomes
    YES.
    @param aBlock Block to be called with each object as its argument.
    @param flag Pointer to a boolean value, which halts further iteration
    when it becomes YES. */
- (id) do:aBlock until:(BOOL *)flag;

/*! Calls a block with each object in the OrdCltn, starting with the last
    and proceeding backwards to the first.
    @param aBlock Block to be called with each object as its argument. */
- reverseDo:aBlock;

- find:anObject;
- findMatching:anObject;
- (BOOL)includes:anObject;
- findSTR:(STR)aString;
- (BOOL)contains:anObject;
- (unsigned)offsetOf:anObject;

- printOn:(IOD)aFile;

- fileOutOn:aFiler;
- fileInFrom:aFiler;

/* private */
- freeAll;
- ARC_dealloc;

- (objcol_t)objcolvalue;
- (uintptr_t)hash;

- addYourself;

- couldntfind;

@end

#endif /* __OBJCLTN_H__ */

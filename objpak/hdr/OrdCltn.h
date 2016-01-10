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
 * @abstract Ordered collection of objects.
 * @discussion Stores objects in a user-ordered form similar to the C++ STL's
 * Vector.
 * Objects at any specified index may be retrieved, removed, or inserted. The
 * index begins at 0 for the first object, and ends at
 * <em>@link size @/link - 1</em> for the last.
 * Object ordering matches the order of insertion, or can be manually altered.
 * @indexgroup Collection
 */
@interface OrdCltn : Cltn
{
    struct objcol value;
}

/*! @functiongroup Factory */

+ new;

/*!
 * Creates a new empty collection pre-sized to hold at least the specified
 * number of objects without need to expand.
 * @param n Space for how many objects to reserve.
 */
+ (id) new:(unsigned)n;

/*!
 * Creates a collection with the specified objects added.
 *
 * This may be used as such:
 * <tt>OrdCltn * someCltn = [OrdCltn with:3,Object1,Object2,Object3];</tt>
 * @param nArgs Number of objects provided to be added.
 * @param ... Objects to be added.
 */
+ (id)with:(int)nArgs, ...;

/*!
 * Creates a collection with the two specified objects added.
 * @param firstObject First object to add to the newly created collection.
 * @param nextObject Second object to add.
 */
+ with:firstObject with:nextObject;

+ add:firstObject;

/*! @functiongroup Instance management */

/*!
 * Copies the OrdCltn. The objects themselves are not copied, only their
 * identifiers, so the contents are 100% identical to the original OrdCltn.
 */
- copy;

/*! Copies the OrdCltn, sending a deepCopy message to each object contained. */
- deepCopy;

/*! Empties the OrdCltn. */
- emptyYourself;
- freeContents;
- free;

/*! @functiongroup Inquiry */

/*! Queries the OrdCltn, returning the number of objects stored in it. */
- (unsigned)size;

/*! Queries the OrdCltn on whether it is empty.
    @return YES if it is empty, NO if it is not. */
- (BOOL)isEmpty;

/*! Requests the offset of the last element.
    @return Offset of the last element if OrdCltn is not empty, -1 if it is. */
- (unsigned)lastOffset;
- eachElement;

/*!
 * Compares the OrdCltn with another collection.
 *
 * If the specified object is another collection, iterates through each
 * indexed position. If each element of both respond affirmatively to the
 * <em>isEqual:</em> message in turn, the collections are considered equal.
 */
- (BOOL)isEqual:aCltn;

/*! @functiongroup Adding */

/*!
 * Add an object to the end of the collection.
 * @param anObject Object to add.
 */
- add:anObject;

/*!
 * Add an object as the first in the collection.
 *
 * Any extant objects are accordingly moved up to the next higher offset.
 * @param newObject Object to add.
 */
- addFirst:newObject;

- addLast:newObject;

/*!
 * Add an object, but only if the same object isn't already there.
 *
 * Equality here is determined by equal object addresses.
 * @param anObject Object to add.
 */
- addIfAbsent:anObject;

/*!
 * Add an object, but only if a matching object isn't already there.
 *
 * Matching is determined using the @link isEqual: @/link method.
 * @param anObject Object to add.
 */
- addIfAbsentMatching:anObject;

/*!
 * Add an object at the specified position.
 *
 * If the specified offset is greater than the size of the collection, an
 * OutOfBounds exception is signaled.
 * @param anOffset Offset at which to insert the object.
 * @param anObject Object to add.
 */
- (id)at:(unsigned)anOffset insert:anObject;

/*!
 * Add an object positioned immediately after a specified object.
 *
 * If the specified object is not found in the collection, a Could not find
 * object exception is signaled.
 * @param newObject Object to add.
 * @param oldObject Object to add newObject after.
 */
- insert:newObject after:oldObject;

/*!
 * Add an object positioned immediately before a specified object.
 *
 * @param newObject Object to add.
 * @param oldObject Object to add newObject before.
 */
- insert:newObject before:oldObject;

/*! @functiongroup Indexed retrieval */

/*! Retrieves the first object in the collection.
    If the collection is empty, returns nil. */
- firstElement;

/*! Retrieves the last object in the collection.
    If the collection is empty, returns nil. */
- lastElement;

/*!
 * Retrieves the object positioned immediately after anObject.
 *
 * If the specified object is not found in the collection, a Could not find
 * object exception is signaled. If the object is the last in the collection,
 * <em>nil</em> is returned.
 * @param anObject Object whose immediately-following neighbour is retrieved.
 */
- after:anObject;

/*!
 * Retrieves the object positioned immediately before anObject.
 *
 * If the specified object is not found in the collection, a Could not find
 * object exception is signaled. If the object is the first in the collection,
 * <em>nil</em> is returned.
 * @param anObject Object whose immediately-preceding neighbour is retrieved.
 */
- before:anObject;

/*!
 * Retrieves the object positioned at the specified offset.
 *
 * If the specified offset exceeds the size of the collection, an OutOfBounds
 * exception is signaled. Offsets begin at 0 for the first object and end at
 * the OrdCltn's size minus 1 for the last.
 * @param anOffset Offset at which to retrieve an object.
 */
- (id)at:(unsigned)anOffset;

/*!
 * Retrieves the object at a specified offset and replaces it with another.
 *
 * If the specified offset exceeds the size of the collection, an OutOfBounds
 * exception is signaled.
 * @param anOffset Offset at which to retrieve & replace an object.
 * @param anObject Object to replace the prior object with.
 * @return The object previously at the specified offset.
 */
- (id)at:(unsigned)anOffset put:anObject;

/*! @functiongroup Removal */

/*!
 * Removes the first object from the collection, returning it.
 *
 * If the collection is empty, returns <em>nil</em>.
 */
- removeFirst;

/*!
 * Removes the last object from the collection, returning it.
 */
- removeLast;

/*!
 * Removes the object at the specified offset, returning it.
 *
 * If the specified offset exceeds collection size, signals an OutOfBounds
 * exception.
 * @param anOffset Offset at which to remove and return object.
 */
- (id)removeAt:(unsigned)anOffset;

- (id)removeAtIndex:(unsigned)anOffset;

/*!
 * Removes the exact object specified, returning it.
 *
 * If the specified object could not be found, returns nil.
 * @param anObject Object to be removed from the collection.
 */
- remove:oldObject;

/*!
 * Removes the exact object specified, returning it. If unfound, calls a block.
 *
 * If the specified object could not be found, the specified exception block
 * is called, the block's return value being returned.
 * The @link remove: @/link method can thus be defined as such:
 * <tt>[someCltn remove: someObject ifAbsent:{ nil }];</tt>
 * @param anObject Object to be removed from the collection.
 * @param exceptionBlock @link Block @/link to be evaluated if anObject not
 * found.
 */
- remove:oldObject ifAbsent:exceptionBlock;

/*! @functiongroup Testing contents */

/*!
 * Asks whether the collection includes all the items in another specified
 * collection.
 *
 * This is effected through sending an @link includes: @/link message for each
 * element. If every such message is answered YES, this message replies YES.
 * If any are not found in the receiver, then the reply is NO.
 * @param aCltn Collection whose entries' presence are to be tested for in the
 * receiving collection.
 * @return YES if receiving collection includes every entry of <em>aCltn</em>,
 * NO if not. */
- (BOOL)includesAllOf:aCltn;

/*!
 * Asks whether the collection includes any of the items in another specified
 * collection.
 *
 * This is effected through sending an @link includes: @/link message for each
 * element. If any of these messages are answered with YES, then the reply to
 * this message is YES. If none, NO.
 * @param aCltn Collection whose entries' presence are to be tested for in the
 * receiving collection.
 * @return YES if receiving collection includes any entry of <em>aCltn</em>,
 * NO if not. */
- (BOOL)includesAnyOf:aCltn;

/*! @functiongroup Adding and removing contents */

/*!
 * Adds each member of the specified collection to the receiver.
 *
 * The specified collection may in fact not be a collection at all. It simply
 * needs to respond to @link eachElement @/link as a collection does. If the
 * specified collection is <em>nil</em>, then no action is taken.
 * @param aCltn Collection whose entries are to be added to the receiver.
 */
- addAll:aCltn;
- addContentsOf:aCltn;
- addContentsTo:aCltn;

/*!
 * Removes each member of the specified collection from the receiver.
 *
 * Objects are removed if they are the same object (equal address) as an object
 * in the specified collection. If the specified collection is <em>nil</em>,
 * then no action is taken.
 * @param aCltn Collection whose entries are to be removed from the receiver.
 */
- removeAll:aCltn;
- removeContentsFrom:aCltn;
- removeContentsOf:aCltn;

/*! @functiongroup Combining */

/*!
 * Returns a new collection formed of the intersection between the receiver and
 * another specified collection.
 *
 * The new collection contains only those objects found in both the receiver
 * and in the specified collection. The specified collection may in fact not
 * be a collection at all. It simply needs to respond to @link find: @/link as
 * a collection does.
 * @param bag Collection to intersect receiver with.
 */
- intersection:bag;

/*!
 * Returns a new collection formed of the union between the receiver and
 * another specified collection.
 *
 * The new collection contains all the elements found in the receiver and in
 * the specified collection. The specified collection may in fact not be a
 * collection at all. It simply needs to respond to @link eachElement @/link as
 * a collection does.
 * @param bag Collection to unite receiver with.
 */
- union:bag;

/*!
 * Returns a new collection formed of the difference between the receiver and
 * another specified collection.
 *
 * The new collection contains only those objects found in the receiver but not
 * found in the specified collection.
 * @param bag Collection to differentiate receiver with.
 */
- difference:bag;

/*! @functiongroup Conversion */

/*! Converts the collection to a Set. */
- asSet;

/*! Converts the collection to an OrdCltn. Returns itself. */
- asOrdCltn;

/*! @functiongroup Functional */

/*!
 * Returns the first entry in the receiver for which a specified block
 * evaluates as true.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to non-nil, then nil is returned.
 * @param aBlock Block with which to evaluate each object.
 */
- detect:aBlock;

/*!
 * Returns the first entry in the receiver for which a specified block
 * evaluates as true; if none evaluate as true, returns the result of a
 * specified block.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to non-nil, then the second specified block is evaluated;
 * its return value is returned by the message.
 * @param aBlock Block with which to evaluate each object.
 * @param noneBlock Block to evaluate and return value thereof if no object
 * evaluates non-nil with <em>aBlock</em>.
 */
- detect:aBlock ifNone:noneBlock;

/*!
 * Returns a new OrdCltn containing each object a specified block evaluates to
 * non-nil with.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to non-nil, then an empty OrdCltn is returned.
 * @param aBlock Block with which to evaluate each object.
 */
- select:testBlock;

/*!
 * Returns a new OrdCltn containing each object a specified block evaluates to
 * nil with.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to nil, then an empty OrdCltn is returned.
 * @param aBlock Block with which to evaluate each object.
 */
- reject:testBlock;

/*!
 * Returns a new OrdCltn containing the result of applying a block to each
 * object in the receiver in turn.
 *
 * The block receives each object in turn as its sole parameter. The block
 * should return another object. If the block returns <em>nil</em>, then for
 * this object nothing is added to the new collection.
 * @param aBlock Block with which to evaluate each object.
 */
- collect:transformBlock;

/*!
 * Returns the number of entries for which a specified block evaluates to a
 * non-<em>nil</em> value with.
 *
 * The block receives each object in turn as its sole parameter.
 * @param aBlock Block with which to evaluate each object.
 */
- (unsigned)count:aBlock;

/*! @functiongroup Enumeration */

/*!
 * Asks each object in the collection to perform a specified selector.
 * @param aSelector Selector for each object to perform.
 */
- (id)elementsPerform:(SEL)aSelector;

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

/*! @functiongroup Locating */

/*!
 * Returns the first object equal (address-equality) to a specified object.
 * If no such object is found, returns nil.
 * @param anObject Object to find in the collection.
 */
- find:anObject;

/*!
 * Returns the first object matching (@link isEqual: @/link) a specified
 * object.
 * If no such object is found, returns nil.
 * @param anObject Object to find a match for in the collection.
 */
- findMatching:anObject;

/*!
 * Inquires as to whether an object matching a specified object is in the
 * collection.
 * Matching is in terms of the @link isEqual: @/link message.
 * @param anObject Object to find a match for in the collection.
 * @return YES if a matching object is found; NO if not.
 */
- (BOOL)includes:anObject;

- findSTR:(STR)aString;

/*!
 * Inquires as to whether an object is in the collection.
 * Equality is in terms of address equality.
 * @param anObject Object to find in the collection.
 * @return YES if the object is found; NO if not.
 */
- (BOOL)contains:anObject;

/*!
 * Returns the offset of a specified object in the collection.
 * If no such object is found, returns -1.
 * @param anObject Object to find in the collection.
 */
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

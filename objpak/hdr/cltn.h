/*
 * Portable Object Compiler (c) 1997,98,2003.  All Rights Reserved.
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

#ifndef __CLTN_H__
#define __CLTN_H__

#include <stdio.h> /* FILE */
#include "Object.h"

@class String;

/*!
 * @abstract Collection of objects
 * @discussion Defines a common interface for working with different types of
 * collections of objects. The specified messages are appropriate for working
 * with anything from a vector (@link OrdCltn @/link) to a set
 * (@link Set @/link) or even a stack (@link Stack @/link).
 * @indexgroup Collection
 */
@protocol Cltn

/*! @functiongroup Factory */

/*!
 * Creates a collection with the specified objects added.
 *
 * This may be used as such:
 * <tt>id someCltn = [ACollectionClass with:3,Object1,Object2,Object3];</tt>
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

/*! Converts the collection to an OrdCltn. */
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
 * Returns a new collection containing each object a specified block evaluates
 * to
 * non-nil with.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to non-nil, then an empty collection is returned.
 * @param aBlock Block with which to evaluate each object.
 */
- select:testBlock;

/*!
 * Returns a new collection containing each object a specified block evaluates
 * to
 * nil with.
 *
 * The block receives each object in turn as its sole parameter. If the block
 * evaluates nothing to nil, then an empty collection is returned.
 * @param aBlock Block with which to evaluate each object.
 */
- reject:testBlock;

/*!
 * Returns a new collection containing the result of applying a block to each
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

/*! Calls a block with each object in the collection, passing in turn each
    object as the single parameter to the block.
    @param aBlock Block to be called with each object as its argument. */
- do:aBlock;

/*! Calls a block with each object in the collection, until a BOOL becomes
    YES.
    @param aBlock Block to be called with each object as its argument.
    @param flag Pointer to a boolean value, which halts further iteration
    when it becomes YES. */
- (id) do:aBlock until:(BOOL *)flag;
@end

@interface Cltn : Object <Cltn>
- (String)componentsJoinedByString:aString;

/* private */
- eachElement;
- (BOOL)includes:anObject;
- add:anObject;
- remove:anObject;
- addYourself;
- emptyYourself;
- perform:(SEL)aSel with:a with:b with:c;

@end

#endif /* __CLTN_H__ */

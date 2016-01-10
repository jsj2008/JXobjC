/*
 * Portable Object Compiler (c) 1997,98.  All Rights Reserved.
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

#ifndef __OBJDIC_H__
#define __OBJDIC_H__

#include <stdio.h>
#include "Object.h"

/*!
 Stores associations of keys to values. For each key, a value is associated,
 and with that key the value may be accessed.
 @indexgroup Collection
 */
@interface Dictionary : Object
{
    id associations;
}

+ new;

/*! @functiongroup Instance management */

/*! Copies the dictionary. The associations are copied but the keys and values
    point to the same objects as in the original. */
- copy;

/*! Copies the dictionary, each key and value being sent a deepCopy message in
    turn. */
- deepCopy;

/*! Empties the dictionary of all associations. */
- emptyYourself;
- freeContents;
- freeAll;
- free;

/*! @functiongroup Introspection */

/*! Query the size of the dictionary in terms of the count of key-value
    associations.
    @return The number of key-value associations. */
- (unsigned)size;

/*! Queries the Dictionary on whether it is empty.
    @return YES if it is empty, NO if it is not. */
- (BOOL)isEmpty;

/*! Queries the dictionary to find out whether it includes an object as
    a key.
    @param aKey Which object's presence as a key in the dictionary should be
    checked.
    @return YES if aKey is in the dictionary, NO if not. */
- (BOOL)includesKey:aKey;

/*! @functiongroup Comparison */

/*! Returns the unique hash of the dictionary, combining the hash of each
    key and value. */
- (uintptr_t)hash;

/*!
 * Compares the dictionary to another.
 *
 * If each key and value in turn responds with YES to <em>isEqual:</em>,
 * returnsYES.
 * @param aDic Dictionary to compare with.
 */
- (BOOL)isEqual:aDic;

/*! @functiongroup Indexed retrieval */

/*!
 * Retrieves the value at the specified key.
 *
 * The Key is located in the dictionary using @link isEqual: @/link.
 * If the key is not found, returns <em>nil</em>.
 * @param aKey Key to find value for.
 */
- atKey:aKey;

/*!
 * Retrieves the value at the specified key, evaluating a specified block if
 * no such key is found in the dictionary and returning its result.
 *
 * @param aKey Key to find value for.
 * @param exceptionBlock Block to be evaluated and value returned if key is
 * not found.
 */
- atKey:aKey ifAbsent:exceptionBlock;

- atKeySTR:(STR)strKey;

/*! @functiongroup Indexed insertion */

/*!
 * Inserts the specified value for the specified key.
 *
 * If a key that @link isEqual: @/link to the specified key is found in the
 * dictionary, returns the previous value for that key. Otherwise, returns
 * <em>nil</em>.
 * @param aKey Key to insert value for.
 * @param anObject Value to associate with <em>aKey</em>.
 */
- atKey:aKey put:anObject;

- atKeySTR:(STR)strKey put:anObject;

/*! @functiongroup Removal */

/*!
 * Removes the association keyed to the specified key and returns its value.
 *
 * If no such key is found, the NotFound exception is signaled.
 * @param key Key whose according association is to be removed.
 */
- removeKey:key;

/*!
 * Removes the association keyed to the specified key and returns its value. If
 * such a key is not found, returns the result of the specified block.
 *
 * @param key Key whose according association is to be removed.
 * @param aBlock Block to be evaluated & value returned if key is not found.
 */
- removeKey:key ifAbsent:aBlock;

/*! @functiongroup Iteration */

/*!
 * Calls a block with each key in the dictionary, passing a single parameter
 * to the block, the current key.
 * @param aBlock Block to be called with each key as an argument.
 */
- keysDo:aBlock;

/*! Returns a sequence of each key in the dictionary. */
- eachKey;

/*! Returns a sequence of each value in the dictionary. */
- eachValue;

- printOn:(IOD)aFile;

/* private */
- copyAssociations;
- deepCopyAssociations;
- ARC_dealloc;

- associations;
- (id *)associationsRef;

- associationAt:aKey;
@end

#endif /* __OBJDIC_H__ */

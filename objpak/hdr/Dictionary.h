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

/*! Query the size of the dictionary in terms of the count of key-value
    associations.
    @return The number of key-value associations. */
- (unsigned)size;
- (BOOL)isEmpty;

/*! Queries the dictionary to find out whether it includes an object as
    a key.
    @param aKey Which object's presence as a key in the dictionary should be
    checked.
    @return YES if aKey is in the dictionary, NO if not. */
- (BOOL)includesKey:aKey;

- (uintptr_t)hash;
- (BOOL)isEqual:aDic;

- atKey:aKey;
- atKey:aKey ifAbsent:exceptionBlock;
- atKeySTR:(STR)strKey;
- atKey:aKey put:anObject;
- atKeySTR:(STR)strKey put:anObject;
- eachKey;
- eachValue;

- removeKey:key;
- removeKey:key ifAbsent:aBlock;

/*! Calls a block with each key in the dictionary, passing a single parameter
    to the block, the current key.
    @param aBlock Block to be called with each key as an argument. */
- keysDo:aBlock;

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

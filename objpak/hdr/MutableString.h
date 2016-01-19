/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef MUTSTR_H__
#define MUTSTR_H__

#include "OCString.h"

/*!
 @abstract Mutable Text string
 @discussion Provides a String that may be freely mutated.
 @indexgroup Collection
 */
@interface MutableString : String

/*! @functiongroup Mutation */

/*!
 * Replaces the byte at the specified offset in the String's buffer, returning
 * the previous byte.
 *
 * If anOffset is greater than @link size @/link, returns zero and does
 * nothing.
 * @param anOffset Byte offset at which to retrieve character.
 * @param aChar Byte to place at the specified offset.
 */
- (char)charAt:(unsigned)anOffset put:(char)aChar;

/*!
 * Concatenates the specified String to the String.
 *
 * @param aString String to concatenate onto the receiver.
 */
- concat:aString;

/*!
 * Concatenates the specified C STR to the String.
 *
 * @param aString C STR to concatenate onto the receiver.
 */
- (id)concatSTR:(STR)aString;

/*!
 * Concatenates the specified number of bytes from the specified byte buffer
 * into the String at the specified offset.
 *
 * Any bytes following the offset are moved forward.
 * @param anOffset Byte offset at which to concatenate bytes.
 * @param aString C byte buffer to concatenate into the receiver.
 * @param n Number of bytes to concatenate into the receiver.
 */
- (id)at:(unsigned)anOffset insert:(char *)aString count:(int)n;

/*!
 * Concatenates the specified String into the String at the specified
 * offset.
 *
 * Any bytes following the offset are moved forward.
 * @param anOffset Byte offset at which to concatenate the String.
 * @param aString String to concatenate into the receiver.
 */
- (id)at:(unsigned)anOffset insert:aString;

/*!
 * Deletes the bytes from the specified offset to the specified offset.
 *
 * Any bytes following the end offset are moved backwards.
 * @param p Byte offset to begin deleting from.
 * @param q Byte offset to end deleting from.
 */
- deleteFrom:(unsigned)p to:(unsigned)q;

/* Replaces the String's contents with those of a specified C STR. */
- assignSTR:(STR)aString;

/* Replaces the String's contents with those of a specified C STR. up to a
 * specified length. */
- assignSTR:(STR)aString length:(unsigned)nChars;

/*! Converts the string to lower-case. */
- toLower;

/*! Converts the string to upper-case. */
- toUpper;

@end

#endif

/*
 * Portable Object Compiler (c) 1997,98,99,2003,09,14.  All Rights Reserved.
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

#ifndef __OBJSTR_H__
#define __OBJSTR_H__

#include <stdarg.h>
#include "array.h"

#ifdef _XtIntrinsic_h
#define String OCString /* remap String class - cant use Xt String */
#endif

#define PCString String

typedef struct objstr
{
    int count;
    int capacity;
    char * ptr;
} * objstr_t;

@class OrdCltn;

/*!
 @abstract Text string
 @discussion Stores a string of bytes terminated with NULL, typically
 representing text. String provides a variety of useful methods for
 their manipulation, oriented towards its use for storing ASCII or UTF-8
 text. Additionally, String instances may be easily initialised from C
 null-terminated byte arrays using @link str: @/link, and from a format string
 and parameters through the C sprintf function using @link sprintf: @/link.
 @indexgroup Collection
 */
@interface String : Array
{
    struct objstr value;
}

/*! @functiongroup Factory & Instance management */

+ new;
+ new:(unsigned)nChars;

/*! Creates a new String from the contents of a C null-terminated byte array.
    @param aString C byte array to initialise the String with. */
+ (id)str:(STR)aString;

/*!
 * Creates a new string form the contents of a C byte array of a specified
 * length.
 * @param aString Byte array to initialise the string with.
 * @param n Number of bytes in the array to be used for initialising the
 * string with. */
+ (id)chars:(STR)aString count:(int)n;

/*! Creates a new String using a format string and varargs parameters via the C
    vsprintf function.
    @param format Format STR in same style as used for sprintf.
    @param : Vararg parameter to vsprintf for filling in the format STR. */
+ (id)vsprintf:(STR)format:(va_list *)ap;

/*!
 * Creates a new String using a format string and parameters via the C
 * sprintf function.
 * @param format Format STR in same style as used for sprintf.
 * @param ... Parameters to sprintf for filling in the format STR. */
+ (id)sprintf:(STR)format, ...;

/*! Returns a copy of the string, including a copy of its internal byte
    buffer. */
- copy;

/*! Returns a mutable copy of the string, including a copy of its internal byte
    buffer. */
- mutableCopy;

- deepCopy;
- free;

/*! @functiongroup Comparison */

/*!
 * Compares the String with another.
 *
 * Analogous to C's strcmp, compares the byte buffers directly. Returns 0
 * if the strings are equal.
 * @param aStr String to compare the receiver with.
 */
- (int)compare:aStr;

/*!
 * Compares the String with a C STR.
 * @param aString C STR to compare the receiver with.
 */
- (int)compareSTR:(STR)aString;

/*! Returns the unique hash value of the string. */
- (uintptr_t)hash;

/*!
 * Compares the String with another String using dictionary ordering.
 *
 * Non-alphanumeric characters and case are ignored in the comparison.
 * Returns 0 if the Strings are dictionary-order equal.
 * @param aStr String to compare the receiver with.
 */
- (int)dictCompare:aStr;

/*!
 * Checks the String for byte-by-byte equality with another String.
 * @param aStr String to check for equality with receiver.
 * @return YES if equal; NO if not.
 */
- (BOOL)isEqual:aStr;

/*!
 * Checks the String for byte-by-byte equality with a C STR.
 * @param aString C STR to check for equality with receiver.
 * @return YES if equal; NO if not.
 */
- (BOOL)isEqualSTR:(STR)aString;

/*!
 * Checks whether the String ends with another specified String.
 * @param aStr String to check the receiver's ending with.
 * @return YES if String ends with aStr; NO if not.
 */
- (BOOL)endsWith:aStr;

- (objstr_t)objstrvalue;

/*! @functiongroup Indexed access */

/*!
 * Returns the number of bytes in the String.
 */
- (unsigned)size;

/*!
 * Retrieves the byte at the specified offset in the String's buffer.
 *
 * If anOffset is greater than @link size @/link, returns zero.
 * @param anOffset Byte offset at which to retrieve character.
 */
- (char)charAt:(unsigned)anOffset;

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

/*! @functiongroup Concatenation */

/*!
 * Concatenates the String's contents to the specified C STR buffer.
 *
 * No length checking is provided. Returns the buffer.
 * @param aBuffer Byte buffer to append the String's contents to.
 */
- (STR)strcat:(STR)aBuffer;

/*!
 * Creates a new string formed by concatenating a specified string to the
 * receiving string.
 *
 * @param aString String to concatenate onto the receiver.
 * @return A new autoreleased string of format "%@%@", rcvr, aString.
 */
- (String *)stringByConcatenating:(String *)aString;

/*!
 * Creates a new string formed by concatenating a specified C STR to the
 * receiving string.
 *
 * @param aString C STR to concatenate onto the receiver.
 * @return A new autoreleased string of format "%@%s", rcvr, aStr.
 */
- (String *)stringByConcatenatingSTR:(STR)aStr;

/*!
 * Creates a new string formed by concatenating the specified number of bytes
 * from the specified byte buffer into the receiving String at the specified
 * offset.
 *
 * Any bytes following the offset are moved forward.
 * @param anOffset Byte offset at which to concatenate bytes.
 * @param aString C byte buffer to concatenate into the receiver.
 * @param n Number of bytes to concatenate into the receiver.
 * @return The new autoreleased string.
 */
- (String *)stringByInsertingAt:(unsigned)anOffset
                          bytes:(char *)aString
                          count:(int)n;

/*!
 * Creates a new string formed by concatenating the specified String into the
 * String at the specified offset.
 *
 * Any bytes following the offset are moved forward.
 * @param anOffset Byte offset at which to concatenate the String.
 * @param aString String to concatenate into the receiver.
 */
- (String *)stringByInsertingAt:(unsigned)anOffset string:(String *)aString;

/* @functiongroup Deletion */

/*!
 * Returns a new string formed by deleting the bytes from the specified offset
 * to the specified offset.
 *
 * Any bytes following the end offset are moved backwards.
 * @param p Byte offset to begin deleting from.
 * @param q Byte offset to end deleting from.
 */
- (String *)stringByDeletingFrom:(unsigned)p to:(unsigned)q;

/*! @functiongroup Substrings */

/*!
 * Returns a substring formed from the bytes in the range specified.
 *
 * If the range is outwith string boundaries, signals an OutOfBounds exception.
 * @param range Range of the receiver to form the substring form.
 */
- (id)substringWithRange:(Range)range;

/*!
 * Returns the range of a substring within the string.
 *
 * If no such substring is found, returns the range of 0 to 0.
 * @param aString Substring to search for in the string.
 */
- (Range)rangeOfString:aString;

/*!
 * Returns an OrdCltn of substrings, split from the string delimited by each
 * instance of the specified separator.
 *
 * If no such separators are found, returns an OrdCltn containing a copy of
 * the receiver String.
 * @param separator String delimiting each component substring.
 */
- (OrdCltn *)componentsSeparatedByString:separator;

/*! @functiongroup Conversion */

/*! Returns the double value of the string as determined by C's atof()
    function. */
- (double)asDouble;

/*! Returns the int value of the string as determined by C's atoi()
    function. */
- (int)asInt;

/*! Returns the long value of the string as determined by C's atol()
    function */
- (long)asLong;

/*!
 * Copies the byte buffer of the String into the specified buffer, up to a
 * specified maximum number of bytes.
 * @param aBuffer Buffer to copy the String's byte buffer into.
 * @param aSize Maximum number of bytes to copy.
 */
- (id)asSTR:(STR)aBuffer maxSize:(int)aSize;

/*! Returns a pointer to the null-terminated byte buffer of the String. */
- (STR)str;

/*! Returns a pointer to a copy of the null-terminated byte buffer of the
    String. */
- (STR)strCopy;

/*! Converts the string to lower-case. */
- toLower;

/*! Converts the string to upper-case. */
- toUpper;

- printOn:(IOD)aFile;

- fileOutOn:aFiler;
- fileInFrom:aFiler;

@end

#endif /* __OBJSTR_H__ */

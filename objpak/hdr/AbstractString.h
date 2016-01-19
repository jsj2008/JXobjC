#include <stdarg.h>
#include "array.h"

#ifndef ABSTRSTR_H__
#define ABSTRSTR_H__

typedef struct objstr
{
    int count;
    int capacity;
    char * ptr;
} * objstr_t;

/*!
 * @abstract Abstract text string
 * @discussion For objects storing a string of bytes terminated with NULL,
 * typically representing text. The String provides a variety of useful methods
 * for their manipulation, oriented towards  use for storing ASCII or UTF-8
 * text.
 * Additionally, String-conforming objects may be easily initialised from C
 * null-terminated byte arrays using @link str: @/link, and from a format string
 * and parameters through the C sprintf function using @link sprintf: @/link.
 *
 * This class ought never to be used directly. The subclasses such as String
 * should be used instead. Although ConstantString is a
 * @indexgroup Collection
 */
@interface AbstractString : Array
{
    union
    {
        struct objstr value;
        struct
        {
            int count, int capacity;
            char * ptr;
        }
    }
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

- concatenateSTR:(STR)aString;

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

/* @functiongroup Deletion */

/*!
 * Deletes the bytes from the specified offset to the specified offset.
 *
 * Any bytes following the end offset are moved backwards.
 * @param p Byte offset to begin deleting from.
 * @param q Byte offset to end deleting from.
 */
- deleteFrom:(unsigned)p to:(unsigned)q;

- assignSTR:(STR)aString;
- assignSTR:(STR)aString length:(unsigned)nChars;

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
- componentsSeparatedByString:separator;

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

#endif

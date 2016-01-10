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

/*! @group Instance management */

+ new;
+ new:(unsigned)nChars;

/*! Creates a new String from the contents of a C null-terminated byte array.
    @param aString C byte array to initialise the String with. */
+ (id)str:(STR)aString;

+ chars:(STR)aString count:(int)n;
+ vsprintf:(STR)format:(va_list *)ap;

/*! Creates a new String using a format string and parameters via the C
    sprintf function.
    @param format Format STR in same style as used for sprintf.
    @param ... Parameters to sprintf for filling in the format STR. */
+ (id)sprintf:(STR)format, ...;

- copy;
- deepCopy;
- free;

- (int)compare:aStr;
- (int)compareSTR:(STR)aString;
- (uintptr_t)hash;
- (int)dictCompare:aStr;
- (BOOL)isEqual:aStr;
- (BOOL)isEqualSTR:(STR)aString;
- (BOOL)endsWith:aStr;

- (objstr_t)objstrvalue;
- (unsigned)size;
- (char)charAt:(unsigned)anOffset;
- (char)charAt:(unsigned)anOffset put:(char)aChar;

- (STR)strcat:(STR)aBuffer;
- concat:aString;
- concatSTR:(STR)aString;
- concatenateSTR:(STR)aString;
- at:(unsigned)anOffset insert:(char *)aString count:(int)n;
- at:(unsigned)anOffset insert:aString;
- deleteFrom:(unsigned)p to:(unsigned)q;
- assignSTR:(STR)aString;
- assignSTR:(STR)aString length:(unsigned)nChars;

- substringWithRange:(Range)range;
- (Range)rangeOfString:aString;
- componentsSeparatedByString:separator;

- (double)asDouble;
- (int)asInt;
- (long)asLong;
- asSTR:(STR)aBuffer maxSize:(int)aSize;
- (STR)str;
- (STR)strCopy;

- toLower;
- toUpper;

- printOn:(IOD)aFile;

#ifdef __PORTABLE_OBJC__
- fileOutOn:aFiler;
- fileInFrom:aFiler;
#endif /* __PORTABLE_OBJC__ */

@end

/* some defs needed when cross-compiling with a DIFFERENT compiler */
/* placed this here 'cause we will have a different objcrt.h and Object.h */

#if !defined(__PORTABLE_OBJC__)
#if !defined(OCLONGLONG)

void * OC_Malloc (size_t);          /* allocate memory from the system */
void * OC_Realloc (void *, size_t); /* reallocate memory from the system */

#endif /* OCLONGLONG */

void * OC_Calloc (size_t);       /* clear memory */
void * OC_MallocAtomic (size_t); /* allocate memory from the system */
void *
OC_Free (void * data); /* deallocate OC_Malloc'ed memory and return NULL */

#endif /* __PORTABLE_OBJC__ */

#endif /* __OBJSTR_H__ */

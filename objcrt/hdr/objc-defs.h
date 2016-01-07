/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef OBJC_DEFS_H
#define OBJC_DEFS_H

#include <stdio.h>  /* FILE */
#include <stddef.h> /* size_t */

#ifndef EXPORT
#define EXPORT /* empty */
#endif

#ifndef EXTERNC
#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif
#endif

/* The traditional Objective C types (see Brad Cox' book)
 */

typedef char * SEL;          /* Uniqued String for Selector */
typedef char * TYP;          /* Type description for a method */
typedef char * STR;          /* C, NULL-terminated, String */
typedef char BOOL;           /* Boolean */
typedef FILE * IOD;          /* I/O Device */
typedef id SHR;              /* type of class, for us, it's id */
typedef double TimeInterval; /* time interval in seconds */

#ifdef __cplusplus
typedef id (*IMP) (...); /* Method pointer */
#else
typedef id (*IMP) (); /* Method pointer */
#endif

typedef void (*ARGIMP) (id, SEL, void *); /* dispatcher */

#if defined(WINDOWS) || defined(__WIN32) || defined(__WIN64)
#define OBJC_WINDOWS 1
typedef SOCKET SocketDescriptor;
#else
typedef int SocketDescriptor;
#endif

/* The traditional Objective C defines
 */

#ifndef YES
#define YES (BOOL)1 /* Boolean TRUE */
#endif

#ifndef NO
#define NO (BOOL)0 /* Boolean FALSE */
#endif

#ifndef nil
#define nil (id)0 /* id of Nil instance */
#endif

typedef struct _Range
{
    size_t location, length;
} Range;

static inline Range MakeRange (size_t location, size_t length)
{
    Range range = {location, length};
    return range;
}

/* varargs for _error error reporting
 */

#include <stdarg.h>
#define OC_VA_LIST va_list
#define OC_VA_START(ap, larg) va_start (ap, larg)
#define OC_VA_ARG(ap, type) va_arg (ap, type)
#define OC_VA_END(ap) va_end (ap)

#endif
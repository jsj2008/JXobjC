/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef OBJC_TYPES_H_
#define OBJC_TYPES_H_

#include "objc-defs.h"

enum JX_objc_type
{
    /* Special types. */
    T_VOID = 'v',
    T_ID   = '@',
    T_SEL  = ':',
    T_STR  = '*',

    /* Regular types. */
    T_CHAR      = 'c',
    T_UCHAR     = 'C',
    T_SHORT     = 's',
    T_USHORT    = 'S',
    T_INT       = 'i',
    T_UINT      = 'I',
    T_LONG      = 'l',
    T_ULONG     = 'L',
    T_LONGLONG  = 'q',
    T_ULONGLONG = 'Q',
    T_FLOAT     = 'f',
    T_DOUBLE    = 'd',

    /* Declarators. */
    T_PTR    = '^',
    T_ARRAY  = '[',
    T_STRUCT = '{',
};

int JX_sizeof_type (TYP type);
TYP JX_skip_type (TYP type);

#endif
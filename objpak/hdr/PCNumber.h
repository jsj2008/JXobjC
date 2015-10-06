/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#import <Object.h>

typedef enum pcnumber_type_e
{
    PCNUMBER_CHAR,
    PCNUMBER_UCHAR,
    PCNUMBER_SHORT,
    PCNUMBER_USHORT,
    PCNUMBER_INT,
    PCNUMBER_UINT,
    PCNUMBER_LONG,
    PCNUMBER_ULONG,
    PCNUMBER_LONGLONG,
    PCNUMBER_ULONGLONG,
    PCNUMBER_SIZE
    PCNUMBER_INT8,
    PCNUMBER_UINT8,
    PCNUMBER_INT16,
    PCNUMBER_UINT16,
    PCNUMBER_INT32,
    PCNUMBER_UINT32,
    PCNUMBER_INT64,
    PCNUMBER_UINT64,
    PCNUMBER_FLOAT,
    PCNUMBER_DOUBLE,
    PCNUMBER_INTPTR,
    PCNUMBER_UINTPTR,
    PCNUMBER_PTRDIFF,
} pcnumber_type_t;

@interface PCNumber: Object
{
    union pcnumber_value_u
    {
        char                 c;
        unsigned char       uc;
        short                s;
        unsigned short      us;
        int                  i;
        unsigned int        ui;
        long                 l;
        unsigned long       ul;
        long long           ll;
        unsigned long long ull;
    } value;
}

@property pcnumber_type_t type;

#define NumFrom(typ, nam) + from##nam:(typ)val
NumFrom(char, Char);
NumFrom(unsigned char, UChar);
NumFrom(short, Short);
NumFrom(unsigned short, UShort);
NumFrom(int, Int);
NumFrom(unsigned int, UInt);
NumFrom(long, Long);
NumFrom(unsigned long, ULong);
NumFrom(long long, LongLong);
NumFrom(unsigned long long, ULongLong);
#undef NumFrom

@end
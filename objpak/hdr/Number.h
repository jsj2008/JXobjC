/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#import <Object.h>

typedef enum number_type_e
{
    NUMBER_CHAR,
    NUMBER_UCHAR,
    NUMBER_SHORT,
    NUMBER_USHORT,
    NUMBER_INT,
    NUMBER_UINT,
    NUMBER_LONG,
    NUMBER_ULONG,
    NUMBER_LONGLONG,
    NUMBER_ULONGLONG,
    NUMBER_SIZE,
    NUMBER_INT8,
    NUMBER_UINT8,
    NUMBER_INT16,
    NUMBER_UINT16,
    NUMBER_INT32,
    NUMBER_UINT32,
    NUMBER_INT64,
    NUMBER_UINT64,
    NUMBER_FLOAT,
    NUMBER_DOUBLE,
    NUMBER_INTPTR,
    NUMBER_UINTPTR,
    NUMBER_PTRDIFF,
} number_type_t;

@interface Number : Object
{
    union number_value_u
    {
        char c;
        unsigned char uc;
        short s;
        unsigned short us;
        int i;
        unsigned int ui;
        long l;
        unsigned long ul;
        long long ll;
        unsigned long long ull;
    } value;
}

@property number_type_t type;

#define NumFrom(typ, nam)                                                      \
    +numberWith##nam : (typ)val;                                               \
    -initWith##nam : (typ)val
NumFrom (char, Char);
NumFrom (unsigned char, UChar);
NumFrom (short, Short);
NumFrom (unsigned short, UShort);
NumFrom (int, Int);
NumFrom (unsigned int, UInt);
NumFrom (long, Long);
NumFrom (unsigned long, ULong);
NumFrom (long long, LongLong);
NumFrom (unsigned long long, ULongLong);
#undef NumFrom

#define NumVal(typ, nam) -(typ)nam##Value
NumVal (char, char);
NumVal (unsigned char, uChar);
NumVal (short, short);
NumVal (unsigned short, uShort);
NumVal (int, int);
NumVal (unsigned int, uInt);
NumVal (long, long);
NumVal (unsigned long, uLong);
NumVal (long long, longLong);
NumVal (unsigned long long, uLongLong);
#undef NumVal

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#import <Object.h>

typedef enum jxnumber_type_e
{
    JXNUMBER_CHAR,
    JXNUMBER_UCHAR,
    JXNUMBER_SHORT,
    JXNUMBER_USHORT,
    JXNUMBER_INT,
    JXNUMBER_UINT,
    JXNUMBER_LONG,
    JXNUMBER_ULONG,
    JXNUMBER_LONGLONG,
    JXNUMBER_ULONGLONG,
    JXNUMBER_SIZE,
	JXNUMBER_INT8,
    JXNUMBER_UINT8,
    JXNUMBER_INT16,
    JXNUMBER_UINT16,
    JXNUMBER_INT32,
    JXNUMBER_UINT32,
    JXNUMBER_INT64,
    JXNUMBER_UINT64,
    JXNUMBER_FLOAT,
    JXNUMBER_DOUBLE,
    JXNUMBER_INTPTR,
    JXNUMBER_UINTPTR,
    JXNUMBER_PTRDIFF,
} jxnumber_type_t;

@interface JXNumber : Object
{
    union jxnumber_value_u
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

@property jxnumber_type_t type;

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
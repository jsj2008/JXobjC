/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import <PCNumber.h>

@implementation PCNumber

#define NumSet(typ, nam, ch, te)                                               \
    -set##nam : (typ)val                                                       \
    {                                                                          \
        value.ch = val;                                                        \
        type     = te;                                                         \
        return self;                                                           \
    }                                                                          \
    +from##nam : (typ)val { return [[super new] set##nam:val]; }
NumSet (char, Char, c, PCNUMBER_CHAR);
NumSet (unsigned char, UChar, uc, PCNUMBER_UCHAR);
NumSet (short, Short, s, PCNUMBER_SHORT);
NumSet (unsigned short, UShort, us, PCNUMBER_USHORT);
NumSet (int, Int, i, PCNUMBER_INT);
NumSet (unsigned int, UInt, ui, PCNUMBER_UINT);
NumSet (long, Long, l, PCNUMBER_LONG);
NumSet (unsigned long, ULong, ul, PCNUMBER_ULONG);
NumSet (long long, LongLong, ll, PCNUMBER_LONGLONG);
NumSet (unsigned long long, ULongLong, ull, PCNUMBER_ULONGLONG);
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
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import <PCNumber.h>

@implementation PCNumber

#define NumSet(typ, nam, ch, te)                                               \
    -initWith##nam : (typ)val                                                  \
    {                                                                          \
        value.ch = val;                                                        \
        type     = te;                                                         \
        return self;                                                           \
    }                                                                          \
    +numberWith##nam : (typ)val { return [[super new] initWith##nam:val]; }
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

#define NumVal(typ, nam, ch)                                                   \
    -(typ)nam##Value { return value.ch; }
NumVal (char, char, c);
NumVal (unsigned char, uChar, uc);
NumVal (short, short, s);
NumVal (unsigned short, uShort, us);
NumVal (int, int, i);
NumVal (unsigned int, uInt, ui);
NumVal (long, long, l);
NumVal (unsigned long, uLong, ul);
NumVal (long long, longLong, ll);
NumVal (unsigned long long, uLongLong, ull);
#undef NumVal

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import <JXNumber.h>

@implementation JXNumber

#define NumSet(typ, nam, ch, te)                                               \
    -initWith##nam : (typ)val                                                  \
    {                                                                          \
        value.ch = val;                                                        \
        type     = te;                                                         \
        return self;                                                           \
    }                                                                          \
    +numberWith##nam : (typ)val { return [[super new] initWith##nam:val]; }
NumSet (char, Char, c, JXNUMBER_CHAR);
NumSet (unsigned char, UChar, uc, JXNUMBER_UCHAR);
NumSet (short, Short, s, JXNUMBER_SHORT);
NumSet (unsigned short, UShort, us, JXNUMBER_USHORT);
NumSet (int, Int, i, JXNUMBER_INT);
NumSet (unsigned int, UInt, ui, JXNUMBER_UINT);
NumSet (long, Long, l, JXNUMBER_LONG);
NumSet (unsigned long, ULong, ul, JXNUMBER_ULONG);
NumSet (long long, LongLong, ll, JXNUMBER_LONGLONG);
NumSet (unsigned long long, ULongLong, ull, JXNUMBER_ULONGLONG);
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
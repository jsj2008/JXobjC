/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import <Number.h>

@implementation Number

- (uintptr_t)hash { return (type * 4) % value.I; }

- (BOOL)isEqual:anObject
{
    if (!anObject || ![anObject isKindOf:Number])
        return NO;
    return [anObject doubleValue] == [self doubleValue];
}

#define NumSet(typ, nam, ch, te)                                               \
    -initWith##nam : (typ)val                                                  \
    {                                                                          \
        value.ch = val;                                                        \
        type     = te;                                                         \
        return self;                                                           \
    }                                                                          \
    +numberWith##nam : (typ)val { return [[super new] initWith##nam:val]; }
NumSet (char, Char, c, NUMBER_CHAR);
NumSet (unsigned char, UChar, C, NUMBER_UCHAR);
NumSet (short, Short, s, NUMBER_SHORT);
NumSet (unsigned short, UShort, S, NUMBER_USHORT);
NumSet (int, Int, i, NUMBER_INT);
NumSet (unsigned int, UInt, I, NUMBER_UINT);
NumSet (long, Long, l, NUMBER_LONG);
NumSet (unsigned long, ULong, L, NUMBER_ULONG);
NumSet (long long, LongLong, q, NUMBER_LONGLONG);
NumSet (unsigned long long, ULongLong, Q, NUMBER_ULONGLONG);
NumSet (float, Float, f, NUMBER_FLOAT);
NumSet (double, Double, d, NUMBER_DOUBLE);
#undef NumFrom

#define NumVal(typ, nam, ch)                                                   \
    -(typ)nam##Value { return value.ch; }
NumVal (char, char, c);
NumVal (unsigned char, uChar, C);
NumVal (short, short, s);
NumVal (unsigned short, uShort, S);
NumVal (int, int, i);
NumVal (unsigned int, uInt, I);
NumVal (long, long, l);
NumVal (unsigned long, uLong, L);
NumVal (long long, longLong, q);
NumVal (unsigned long long, uLongLong, Q);
NumVal (float, float, f);
NumVal (double, double, d);
#undef NumVal

@end
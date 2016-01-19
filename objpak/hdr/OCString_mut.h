/* Copyright (c) 2015,16 D. Mackay. All rights reserved. */

#ifndef OCSTRING_MUT_H
#define OCSTRING_MUT_H

#include "OCString.h"

@interface String () /* mutation */
- concat:aString;
- (id)concatSTR:(STR)aString;
- (id)at:(unsigned)anOffset insert:(char *)aString count:(int)n;
- (id)at:(unsigned)anOffset insert:aString;
- deleteFrom:(unsigned)p to:(unsigned)q;
- assignSTR:(STR)aString;
- assignSTR:(STR)aString length:(unsigned)nChars;
@end

#endif
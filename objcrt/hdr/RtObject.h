/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef __RTOBJECT_H__
#define __RTOBJECT_H__

#include "objcrt.h"
#include <stdarg.h>
#include <string.h>

/*
 * RtObject is the terminal root class.
 * It implements behaviour that virtually every object, even unusual ones,
 * could expect.
 *
 * Users should inherit instead from a primary or secondary root class.
 */
@interface RtObject
{
    id isa;
    unsigned int _refcnt;
    void * _lock;
}

+ initialize;

+ new;
+ alloc;
- init;
- copy;
- deepCopy;
- free;
- increfs;
- decrefs;
- finalise;

- self;
- yourself;

- doesNotRecognize:(SEL)aSelector;
- doesNotUnderstand:aMessage;

- (IMP)methodFor:(SEL)aSelector;
+ (IMP)instanceMethodFor:(SEL)aSelector;

/* private */
- _lock;
- _unlock;
- ARC_dealloc;
@end

#endif

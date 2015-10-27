/*
 * Portable Object Compiler (c) 1997,98,99,2000,03,14.  All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
#ifndef __PROXY_H__
#define __PROXY_H__

#include "objcrt.h"
#include <stdarg.h>
#include <string.h>

@interface Proxy
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

#endif /* __OBJECT_H__ */

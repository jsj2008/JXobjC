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
/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "objc-vector.h"

#include "RtObject.h"
#include "Message.h" /* doesNotUnderstand: stuff */
#include "SideTable/SideTable.h"

@implementation RtObject
/*****************************************************************************
 *
 * Factory Initialization
 *
 ****************************************************************************/

+ initialize { return self; }

+ new { return [[self alloc] init]; }

+ alloc
{
    id newObject = (*JX_alloc) (self, 0);
    return newObject;
}

- init { return self; }

- increfs { return nil; }

- copy
{
    id newObject = (*JX_copy) (self, 0);
    [newObject increfs];
    return newObject;
}

- deepCopy
{
    id newObject = (*JX_copy) (self, 0);
    [newObject increfs];
    return newObject;
}

- free
{
    isa = nil;
    destroySideTableForObject (self);
    return (JX_dealloc) ? (*JX_dealloc) (self) : nil;
}

- decrefs { return nil; }

- ARC_dealloc
{
    [self decrefs];
    return (*JX_dealloc) (self);
}

- finalise { return [self free]; }

- retain { return idincref (self); }

- release { return iddecref (self); }

/*****************************************************************************
 *
 * Identity
 *
 ****************************************************************************/

- self { return self; }

- yourself { return self; }

/*****************************************************************************
 *
 * Unknown Messages
 *
 ****************************************************************************/

- doesNotRecognize:(SEL)aSelector
{
    return [self error:"(%s): Message not recognized by this class (%s).",
                       aSelector, [self str]];
}
- doesNotUnderstand:aMessage
{
    return [self doesNotRecognize:[aMessage selector]];
}

/*****************************************************************************
 *
 * Method Implemenation Lookup
 *
 ****************************************************************************/

- (IMP)methodFor:(SEL)aSelector { return _imp (self, aSelector); }

+ (IMP)instanceMethodFor:(SEL)aSelector { return _impSuper (self, aSelector); }

/*****************************************************************************
 *
 * Synchronisation
 *
 ****************************************************************************/

- _lock
{
    pthread_mutex_lock (mutexForObject (self));
    return self;
}

- _unlock
{
    pthread_mutex_unlock (mutexForObject (self));
    return self;
}

@end

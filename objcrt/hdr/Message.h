/*
 * Portable Object Compiler (c) 1998.  All Rights Reserved.
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

#ifndef __MESSAG_H__
#define __MESSAG_H__

#include <stdio.h>
#include "objcrt.h"
#include "Object.h"

/*!
 Message represents a message made static; it is a reification of the activity
 of sending a message to an object. This is used mainly for forwarding of
 messages by @link doesNotUnderstand: @/link.
 @indexgroup JX Runtime
 */
@interface Message : Object
{
    SEL selector;
    ARGIMP dispatch;
    void * args;
}

/*!
 Creates a new message object.
 @param sel Selector name.
 @param disp Message dispatcher. This is a compiler-generated function
 which will decode the arguments and execute the associated IMP.
 @param arg Argument structure. This is a struct beginning with the return
 type, followed by each argument in sequence.
 @return A new message object initialised with the specified parameters.
 */
+ selector:(SEL)sel dispatch:(ARGIMP)disp args:(void *)arg;

/*!
 Finds the selector of the message.
 @return The selector of this message.
 */
- (SEL)selector;

/*!
 Sends the message through the specified dispatcher.
 @param receiver The object to send the message to.
 */
- sentTo:receiver;

/* private */

+ new;
- selector:(SEL)s dispatch:(ARGIMP)d args:(void *)a;
- printOn:(IOD)anIod;

@end

#endif /* __MESSAG_H__ */

/*
 * Portable Object Compiler (c) 2003.  All Rights Reserved.
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

#ifndef __EXCEPTN_H__
#define __EXCEPTN_H__

#include <stdio.h>
#include "Object.h"

/*!
 Used to handle exceptions. An Exception may be signalled using:
 @code
 [[[Exception alloc] init] signal:"This is an exception message."];
 @endcode
 A handler @link Block @/link for classes of exceptions is passed the
 signalling instance of Exception (or an instance one of its subclasses) as its
 single parameter.
 @indexgroup JX Runtime
 */
@interface Exception : Object
{
    id messageText;
    id tag;
    id resumeHandler;
} :
{
  id handler;
}

/*! Signals a new exception. */
+ signal;

/*! Signals a new exception with an STR message.
    @param message Exception message STR. */
+ signal:(STR)message;
- free;

- signal;
- signal:(STR)message;
- messageText;
- (STR)str;
- messageText:message;
- str:(STR)message;

/*! Resignals a new exception with another Exception instance.
    @param replacementException Exception message STR. */
- resignalAs:replacementException;
- resume;

/* private */

+ install:aHandler;
- defaultAction;

@end

#endif /* __EXCEPTN_H__ */

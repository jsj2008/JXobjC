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

#include "Object.h"
#include "Exceptn.h"
#include "Block.h"

@implementation Exception

/*****************************************************************************
 *
 * Installing Handlers
 *
 ****************************************************************************/

+ install:aHandler
{
    if (handler)
    {
        handler = [aHandler push:handler];
    }
    else
    {
        handler = aHandler;
    }
    return self;
}

/*****************************************************************************
 *
 * Default Action
 *
 ****************************************************************************/

- defaultAction { return [self subclassResponsibility]; }

/*****************************************************************************
 *
 * Creation
 *
 ****************************************************************************/

+ signal { return [[self new] signal]; }

+ signal:(STR)message { return [[self new] signal:message]; }

- free
{
    if (messageText)
        messageText = [messageText free];
    return [super free];
}

/*****************************************************************************
 *
 * Signalling
 *
 ****************************************************************************/

- signal
{
    if (handler)
    {
        resumeHandler = handler;
        handler       = [handler pop];
        return [resumeHandler value:self];
    }
    else
    {
        return [self halt:messageText];
    }
}

- signal:(STR)message { return [[self str:message] signal]; }

- messageText { return messageText; }

- (STR)str { return [messageText str]; }

- messageText:message
{
    messageText = message;
    return self;
}

- str:(STR)message
{
    static id MsgClass;
    if (!MsgClass)
        MsgClass = [self findClass:"String"];
    return [self messageText:[MsgClass str:message]];
}

/*****************************************************************************
 *
 * Re-Signalling
 *
 ****************************************************************************/

- resignalAs:replacementException { return [self notImplemented]; }

- resume
{
    handler = resumeHandler;
    return self;
}
@end
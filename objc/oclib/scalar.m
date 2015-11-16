/*
 * Copyright (c) 1999,2014 David Stes.
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

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include "Object.h"
#include "OCString.h"
#include "node.h"
#include "type.h"
#include "var.h"
#include "scalar.h"

@implementation Scalar

- type { return type; }

- errorconvert
{
    gstderr ();
    [type gen];
    gnormal ();
    return [self error:"don't know how to convert type"];
}

- (int)u_int
{
    if (type == t_int)
        return u.un_int;
    if (type == t_char)
        return (int)u.un_char;
    if (type == t_long)
        return (int)u.un_long;
    if (type == t_uns)
        return (int)u.un_uns;
    if (type == t_str)
        return (int)(intptr_t)u.un_str;
    if (type == t_double)
        return (int)u.un_double;
    [self errorconvert];
    return 0;
}

- (unsigned)u_uns
{
    if (type == t_uns)
        return u.un_uns;
    if (type == t_int)
        return (unsigned)u.un_int;
    if (type == t_char)
        return (unsigned)u.un_char;
    if (type == t_long)
        return (unsigned)u.un_long;
    [self errorconvert];
    return 0;
}

- u_int:(int)x
{
    type     = t_int;
    u.un_int = x;
    return self;
}

- u_uns:(unsigned)x
{
    type     = t_uns;
    u.un_uns = x;
    return self;
}

- u_long:(long)x
{
    type      = t_long;
    u.un_long = x;
    return self;
}

- (long)u_long
{
    if (type == t_long)
        return u.un_long;
    if (type == t_int)
        return (long)u.un_int;
    [self errorconvert];
    return 0;
}

- u_char:(char)x
{
    type      = t_char;
    u.un_char = x;
    return self;
}

- (char)u_char
{
    if (type == t_char)
        return u.un_char;
    if (type == t_int)
        return (char)u.un_int;
    [self errorconvert];
    return 0;
}

- u_float:(float)x
{
    type       = t_double;
    u.un_float = x;
    return self;
}

- (float)u_float
{
    if (type == t_double)
        return u.un_float;
    if (type == t_int)
        return (float)u.un_int;
    [self errorconvert];
    return 0;
}

- u_double:(double)x
{
    type        = t_double;
    u.un_double = x;
    return self;
}

- (double)u_double
{
    if (type == t_double)
        return u.un_double;
    if (type == t_int)
        return (double)u.un_int;
    [self errorconvert];
    return 0;
}

- u_str:(char *)x
{
    if (!t_str)
        [self error:"type not initialized"];
    type     = t_str;
    u.un_str = x;
    return self;
}

- (char *)u_str
{
    if (type == t_str)
        return u.un_str;
    if (type == t_int)
        return (char *)(uintptr_t)u.un_int;
    if (type == t_uns)
        return (char *)(uintptr_t)u.un_uns;
    if (type == t_long)
        return (char *)(uintptr_t)u.un_long;
    [self errorconvert];
    return (char *)0;
}

- u_voidstar:(void *)x
{
    type          = t_str;
    u.un_voidstar = x;
    return self;
}

- (void *)u_voidstar
{
    if (type == t_str)
        return u.un_voidstar;
    if (type == t_int)
        return (void *)(uintptr_t)u.un_int;
    [self errorconvert];
    return (void *)0;
}

- u_fp:(FILE *)x
{
    type    = t_str;
    u.un_fp = x;
    return self;
}

- (FILE *)u_fp
{
    if (type == t_str)
        return (FILE *)u.un_fp;
    if (type == t_int)
        return (FILE *)(uintptr_t)u.un_int;
    [self errorconvert];
    return (FILE *)0;
}

- (BOOL)isEqual:x
{
#if 1
    return u.un_int == [x u_int];
#else
    return [super isEqual:x];
#endif
}

- (BOOL)isZero { return u.un_int == 0; }

- increment
{
    u.un_int++;
    return self;
}

- decrement
{
    u.un_int--;
    return self;
}

- (STR)str
{
    static char buffer[255] = {0};

    if (type == t_int)
        sprintf (buffer, "%i", u.un_int);
    if (type == t_char)
        sprintf (buffer, "%c", u.un_char);
    if (type == t_long)
        sprintf (buffer, "%li", u.un_long);
    if (type == t_uns)
        sprintf (buffer, "%u", u.un_uns);
    if (type == t_double)
        sprintf (buffer, "%g", u.un_double);
    if (type == t_str)
        sprintf (buffer, "%s", u.un_str);

    return buffer ?: ([self error:"don't know how to format scalar"], 0);
}

- printOn:(IOD)x
{
    fprintf (x, "%s", [self str]);
    return self;
}

@end

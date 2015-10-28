/*
 * Portable Object Compiler (c) 1997,98,99.  All Rights Reserved.
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

#ifndef __TEXTATTRIBUT_H__
#define __TEXTATTRIBUT_H__

#include <stdio.h>
#include "Object.h"

@interface TextAttribute : Object
{
    unsigned emphasiscode;
}

+ normal;
+ new;
+ bold;
+ emphasiscode:(unsigned)n;

- (unsigned)emphasiscode;
- emphasiscode:(unsigned)c;

- (BOOL)isEqual:attrib;

- (BOOL)dominates:attrib;
- reset;
- (BOOL)set;

- emphasizeScanner:aScanner;

- printOn:(IOD)aFile;
@end

#endif /* __TEXTATTRIBUT_H__ */

/*
 * Portable Object Compiler (c) 1997,98.  All Rights Reserved.
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

#ifndef __OBJSEQ_H__
#define __OBJSEQ_H__

#include "Object.h"

/* the name of this class in ICpak101 is IPSequence */
#define IPSequence Sequence

@interface Sequence : Object
{
    id carrier;
}

- copy;
- free;

- (unsigned)size;

- next;
- peek;
- previous;
- first;
- last;

- printOn:(IOD)aFile;

#if OBJC_BLOCKS
- do:aBlock;
#endif /* OBJC_BLOCKS */

/* private */
- setUpCarrier:aCarrier;
+ over:aCarrier;
- over:aCarrier;
- ARC_dealloc;
@end

#endif /* __OBJSEQ_H__ */

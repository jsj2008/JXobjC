/* Copyright (c) 2016 D. Mackay. All rights reserved. */
/*
 * Portable Object Compiler (c) 1997,98,99,2000,01,04,14.  All Rights Reserved.
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

#ifndef OBJC_ACCESS_H
#define OBJC_ACCESS_H

#ifdef OBJC_REFCNT
static inline BOOL isrefcntclass (Cls_t cls)
{
    return (cls)->clsStatus & CLS_REFCNT;
}
#endif

static inline BOOL isfactory (Cls_t cls)
{
    return (cls)->clsStatus & CLS_FACTORY;
}

static inline BOOL ismeta (Cls_t cls) { return (cls)->clsStatus & CLS_META; }

static inline BOOL iscatgry (Cls_t cls) { return (cls)->clsStatus & CLS_CAT; }

static inline Cls_t getmeta (Cls_t cls)
{
    return ismeta (cls) ? cls : getcls (cls->isa);
}

static inline BOOL initlzd (Cls_t cls)
{
    return getmeta (cls)->clsStatus & CLS_INITIALIZED;
}

static inline void markinitlzd (Cls_t cls)
{
    getmeta (cls)->clsStatus |= CLS_INITIALIZED;
}

static inline BOOL ismapped (Cls_t aCls)
{
    return (aCls)->clsStatus & CLS_MAPPED;
}

static inline void markmapped (Cls_t aCls) { aCls->clsStatus |= CLS_MAPPED; }

static inline id getisa (id anObject)
{
#if !OTBCRT
    return anObject->isa;
#else
    return anObject->ptr->isa;
#endif
}

static inline void setisa (id anObject, id aClass)
{
#if !OTBCRT
    anObject->isa = aClass;
#else
    anObject->ptr->isa = aClass;
#endif
}

static inline long nstsize (id aClass)
{
    return getcls (aClass)->clsSizInstance;
}

#endif

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

#include "objc-defs.h"

#define KNRM "\x1B[0m"
#define KBLD "\x1B[1m"
#define KULN "\x1B[4m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

#ifdef OBJC_REFCNT
INLINE BOOL isrefcntclass (Cls_t cls) { return (cls)->clsStatus & CLS_REFCNT; }
#endif

INLINE BOOL isfactory (Cls_t cls) { return (cls)->clsStatus & CLS_FACTORY; }

INLINE BOOL ismeta (Cls_t cls) { return (cls)->clsStatus & CLS_META; }

INLINE BOOL iscatgry (Cls_t cls) { return (cls)->clsStatus & CLS_CAT; }

INLINE Cls_t getmeta (Cls_t cls)
{
    return ismeta (cls) ? cls : getcls (cls->isa);
}

INLINE BOOL initlzd (Cls_t cls)
{
    return getmeta (cls)->clsStatus & CLS_INITIALIZED;
}

INLINE void markinitlzd (Cls_t cls)
{
    getmeta (cls)->clsStatus |= CLS_INITIALIZED;
}

INLINE BOOL ismapped (Cls_t aCls) { return (aCls)->clsStatus & CLS_MAPPED; }

INLINE void markmapped (Cls_t aCls) { aCls->clsStatus |= CLS_MAPPED; }

INLINE id getisa (id anObject)
{
#if !OTBCRT
    return anObject->isa;
#else
    return anObject->ptr->isa;
#endif
}

INLINE void setisa (id anObject, id aClass)
{
#if !OTBCRT
    anObject->isa = aClass;
#else
    anObject->ptr->isa = aClass;
#endif
}

INLINE long nstsize (id aClass) { return getcls (aClass)->clsSizInstance; }

INLINE objC_iVarList * clsivlist (Cls_t aClass) { return aClass->clsIVars; }

INLINE objC_iVarList * nstivlist (id anObject)
{
    return clsivlist ((Cls_t)getisa (anObject));
}

#endif

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

#include <assert.h>
#include <stdlib.h>

#define OBJCRT_BOEHM 1

#ifdef OBJCRT_BOEHM
#include <gc.h>
#endif
#ifdef OBJC_REFCNT
#pragma OCRefCnt 0 /* if compiled with -refcnt, turn of refcnt now */
#endif

#include "Object.h"
#include "Exceptn.h"
#include "access.h"

/*****************************************************************************
 *
 * Memory management functions
 *
 ****************************************************************************/

id outOfMem = 0; /* must be allocated before error happens */

void EXPORT * OC_Malloc (size_t nBytes)
{
    void * data;

    /* DEC alpha malloc() returns NULL for 0 bytes */
    if (!nBytes)
        nBytes = sizeof (void *);
    if (nBytes > 32 * 1024)
        dbg ("OC_Malloc call for %i bytes\n", nBytes);

    data = GC_MALLOC (nBytes);

    /* signal the OutOfMemory exception */
    if (!data)
        [outOfMem signal];
    return data;
}

void EXPORT * OC_MallocAtomic (size_t nBytes)
{
    void * data;
    /* DEC alpha malloc() returns NULL for 0 bytes */
    if (!nBytes)
        nBytes = sizeof (void *);
    if (nBytes > 32 * 1024)
        dbg ("OC_MallocAtomic call for %i bytes\n", nBytes);

    data = GC_malloc_atomic (nBytes);

    /* signal the OutOfMemory exception */
    if (!data)
        [outOfMem signal];
    return data;
}

void EXPORT * OC_Calloc (size_t nBytes)
{
    char * p;

    p = (char *)GC_MALLOC (nBytes);

    return (void *)p;
}

void EXPORT * OC_Realloc (void * data, size_t nBytes)
{
    /* DEC alpha malloc() returns NULL for 0 bytes */
    if (!nBytes)
        nBytes = sizeof (void *);
    if (nBytes > 32 * 1024)
        dbg ("OC_Realloc call for %i bytes\n", nBytes);

    data = GC_REALLOC (data, nBytes);

    /* signal the OutOfMemory exception */
    if (!data)
        [outOfMem signal];
    return data;
}

void EXPORT * OC_Free (void * data)
{
#ifdef OBJCRT_BOEHM
/* do not call GC_free */
#endif
    return NULL;
}

/*****************************************************************************
 *
 * Object Allocator function vectors
 *
 ****************************************************************************/

#ifdef OTBCRT
static void linkotb (id a, id b, id c)
{
    a->nextinst = b;
    b->previnst = a;
    b->nextinst = c;
    if (c)
        c->previnst = b;
}

static void unlinkotb (id a)
{
    id p = a->previnst;
    id n = a->nextinst;
    if (p)
        p->nextinst = n;
    if (n)
        n->previnst = p;
}
#endif /* OTBCRT */

#ifndef OTBCRT
#define _LOCK(x) (x)->_lock
#else
#define _LOCK(x) (x)->ptr->_lock
#endif

id EXPORT idassign (id * lhs, id rhs) { return (*lhs = rhs); }

id EXPORT idincref (id rhs) { return rhs; }

id EXPORT iddecref (id e) { return nil; }

static void gcfinalise (GC_PTR obj, GC_PTR env) { [(id)obj finalise]; }

static void * gcoalloc (unsigned int aSize)
{
    id ptr = GC_malloc (aSize);
    GC_register_finalizer (ptr, gcfinalise, 0, 0, 0);
    return ptr;
}

static id nstalloc (id aClass, unsigned int nBytes)
{
    id anObject;
    unsigned aSize;

    if (!aClass)
        [Object error:"alloc: nil class"];
    aSize = nstsize (aClass) + nBytes;

#ifndef OTBCRT
    anObject = gcoalloc (aSize);
#else
    anObject      = (id)OC_Malloc (sizeof (struct OTB));
    anObject->ptr = (struct _PRIVATE *)OC_Calloc (aSize);
    linkotb (aClass, anObject, aClass->nextinst);
#endif

    setisa (anObject, aClass);
    _LOCK (anObject) = allocMtx ();

    return anObject;
}

static id nstcopy (id anObject, unsigned int nBytes)
{
    char *p, *q;
    id newObject;
    unsigned aSize;
    id aClass = getisa (anObject);

    aSize = nstsize (aClass) + nBytes;

#ifndef OTBCRT
    newObject = gcoalloc (aSize);
    p         = (char *)newObject;
    q         = (char *)anObject;
#else
    newObject      = (id)OC_Malloc (sizeof (struct OTB));
    newObject->ptr = (struct _PRIVATE *)OC_Malloc (aSize);
    p              = (char *)newObject->ptr;
    q = (char *)anObject->ptr;
    linkotb (aClass, newObject, aClass->nextinst);
#endif

    memcpy (p, q, aSize);
    _LOCK (newObject) = allocMtx ();

    assert (getisa (newObject) == aClass);
    return newObject;
}

static id nstdealloc (id anObject)
{
    setisa (anObject, nil);
    pthread_mutex_destroy (_LOCK (anObject));
    free (_LOCK (anObject));

#ifndef OTBCRT
/* AMGR_free (anObject); */
#else
    unlinkotb (anObject);
    OC_Free (anObject->ptr);
    OC_Free (anObject);
#endif

    return nil;
}

id (*JX_alloc) (id, unsigned int) = nstalloc;
id (*JX_copy) (id, unsigned int) = nstcopy;
id (*JX_dealloc) (id) = nstdealloc;
#if 0
id (*JX_realloc) (id, unsigned int);	/* clash IRIX 6.2 and not used */
#endif

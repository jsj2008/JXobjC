/*
 * Automgr Tracing GC for JX Objective-C
 * Copyright (c) 2015 D. Mackay. All rights reserved.
 * Use is subject to licence terms.
 */

#include <setjmp.h>
#include <stdint.h>
#include <stdlib.h>

#include "automgr.h"
#include "dlmalloc.h"
#include "Object.h"

#define ThrdMgr() ((Automgr *)pthread_getspecific (mgrForThread))

typedef struct _zoneTblEnt
{
    void * start;
    size_t length : 26;
    /* If it is root, then it is never un-marked.
    * If it is copy, then it is copied for new threads.
    * If it is object, we call its ARC_dealloc routine. */
    BOOL marked : 1, traced : 1, tls : 1, root : 1, copy : 1, object : 1;

    struct _zoneTblEnt * next;
} zoneTblEnt;

typedef struct _Automgr
{
    BOOL enabled;
    unsigned short aCnt;
    pthread_mutex_t lock;
    void *stkBegin, *stkEnd;
    zoneTblEnt * zoneTbl;
} Automgr;

static size_t wordSize = sizeof (uintptr_t);
static pthread_key_t mgrForThread;
static pthread_mutexattr_t recursiveAttr;
static mspace AMGRmspace;

void AMGR_delete (zoneTblEnt * toFree);

#define AM_alloc(bytes) mspace_malloc (AMGRmspace, bytes)
#define AM_free(addr) mspace_free (AMGRmspace, addr)

Automgr * AMGR_init (void * stkBegin)
{
    Automgr * mgr = AM_alloc (sizeof (Automgr));
    pthread_mutex_init (&mgr->lock, &recursiveAttr);
    mgr->zoneTbl  = 0;
    mgr->stkBegin = stkBegin;
    mgr->enabled  = NO;
    return mgr;
}

void * AMGR_init_pre_thrd (void * stkBegin)
{
    Automgr * mgr = AMGR_init (stkBegin);
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
    {
        if ((*it)->copy)
        {
            zoneTblEnt * cpy = AM_alloc (sizeof *cpy);
            *cpy             = **it;
            cpy->next        = mgr->zoneTbl;
            mgr->zoneTbl     = cpy;
        }
    }
    return mgr;
}

void AMGR_init_post_thrd (void * mgr)
{
    pthread_setspecific (mgrForThread, mgr);
    AMGR_enable (mgr);
}

void AMGR_main_init (void * stkBegin)
{
    AMGRmspace = create_mspace (0, 0);
    pthread_mutexattr_settype (&recursiveAttr, PTHREAD_MUTEX_RECURSIVE);
    pthread_key_create (&mgrForThread, 0);
    pthread_setspecific (mgrForThread, AMGR_init (stkBegin));
}

void AMGR_enable () { ThrdMgr ()->enabled = YES; }

void AMGR_disable () { ThrdMgr ()->enabled = NO; }

void AMGR_add_zone (void * start, size_t length, BOOL isRoot, BOOL isCopy,
                    BOOL isObject, BOOL isTLS)
{
    Automgr * mgr         = ThrdMgr ();
    zoneTblEnt * newEntry = AM_alloc (sizeof (zoneTblEnt));

    newEntry->start  = start;
    newEntry->length = length;
    newEntry->root   = isRoot;
    newEntry->copy   = isCopy;
    newEntry->object = isObject;
    newEntry->tls    = isTLS;
    newEntry->marked = NO;
    newEntry->traced = NO;

    newEntry->next = mgr->zoneTbl;
    mgr->zoneTbl   = newEntry;
}

void AMGR_remove_zone (void * location)
{
    zoneTblEnt ** it = &((Automgr *)ThrdMgr ())->zoneTbl;
    while (*it)
    {
        if ((*it)->start == location)
        {
            zoneTblEnt * toFree = *it;
            *it = toFree->next;
            AM_free (toFree);
        }
        else
            it = &(*it)->next;
    }
}

zoneTblEnt * AMGR_find_zone (void * location)
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it; it = &(*it)->next)
    {
        if ((*it)->start == location)
            return *it;
    }
    return 0;
}

void AMGR_remove_all_zones ()
{
    zoneTblEnt ** it = &((Automgr *)ThrdMgr ())->zoneTbl;
    while (*it)
    {
        zoneTblEnt * toFree = *it;
        *it = toFree->next;
        AM_free (toFree);
    }
}

/* Thread-specific storage */

void _AMGR_tss_destructor (void * location)
{
    zoneTblEnt * toFree = AMGR_find_zone (location);

    if (toFree->object)
        [(id)location ARC_dealloc];
    else
    {
        free (location);
    }

    AMGR_remove_zone (location);
}

int AMGR_tss_create (void * tssKey, BOOL isRoot, BOOL isCopy, BOOL isObject)
{
    int result = pthread_key_create (tssKey, _AMGR_tss_destructor);
    if (!result)
    {
        AMGR_add_zone (tssKey, sizeof *tssKey, isRoot, isCopy, isObject, YES);
    }
    return result;
}

/* CStdLib equivalents */

inline void AMGR_checkCycle ()
{
    if (ThrdMgr ()->aCnt++ >= 48)
    {
        ThrdMgr ()->aCnt = 0;
        AMGR_cycle ();
    }
}

void * AMGR_alloc (size_t bytes)
{
    void * ptr = malloc (bytes);
    AMGR_add_zone (ptr, bytes, NO, NO, NO, NO);

    return ptr;
}

void * AMGR_ralloc (size_t bytes)
{
    void * ptr = malloc (bytes);
    AMGR_add_zone (ptr, bytes, YES, YES, NO, NO);

    return ptr;
}

void * AMGR_oalloc (size_t bytes)
{
    void * ptr = calloc (1, bytes);
    AMGR_checkCycle ();
    AMGR_add_zone (ptr, bytes, NO, NO, YES, NO);

    return ptr;
}

void * AMGR_calloc (size_t num, size_t bytes)
{
    void * ptr = calloc (num, bytes);

    AMGR_add_zone (ptr, num * bytes, NO, NO, NO, NO);

    return ptr;
}

void * AMGR_realloc (void * location, size_t newBytes)
{
    zoneTblEnt * zone = AMGR_find_zone (location);
    void * newPtr     = realloc (location, newBytes);

    zone->start  = newPtr;
    zone->length = newBytes;

    return newPtr;
}

void AMGR_free (void * location)
{
    AMGR_remove_zone (location);
    free (location);
}

/* This method will, if `location' matches the address of a zone,
 * mark it.
 * Should this check if location falls within the range of a zone, or
 * just equality? */
zoneTblEnt * AMGR_ptr_for_address (uintptr_t location)
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
    {
        if ((*it)->start == (void *)location)
        {
            (*it)->marked = YES;
            return *it;
        }
    }
    return 0;
}

void AMGR_unmark_all_zones ()
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
        ((*it)->marked = NO, (*it)->traced = NO);
}

/* Tracing */

void AMGR_trace_zone (zoneTblEnt * zone)
{
    uintptr_t * curPtr;

    if (zone->traced)
        return;
    else
        zone->traced = YES;

    if (zone->tls)
    {
        zoneTblEnt * content;

        if ((content = AMGR_ptr_for_address ((uintptr_t)pthread_getspecific (
                 *(pthread_key_t *)zone->start))))
            AMGR_trace_zone (content);
        return;
    }

    for (curPtr = (uintptr_t *)zone->start;
         curPtr <= (uintptr_t *)zone->start + zone->length;
         curPtr = (uintptr_t *)(((char *)curPtr) + wordSize))
    {
        zoneTblEnt * found;

        if (*curPtr % wordSize)
            continue;
        else if ((found = AMGR_ptr_for_address (*curPtr)))
            AMGR_trace_zone (found);
    }
}

void AMGR_trace_terminal_stack_extent ()
{
    Automgr * mgr = ThrdMgr ();
    zoneTblEnt * found;
    uintptr_t *final, *curPtr;
    void * top = 0;
    final      = (uintptr_t *)&top;

    if (mgr->stkBegin > (void *)final)
        for (curPtr = final; curPtr <= (uintptr_t *)mgr->stkBegin;
             curPtr = (uintptr_t *)(((char *)curPtr) + wordSize))
        {
            if (*curPtr % wordSize)
                continue;
            else if ((found = AMGR_ptr_for_address (*curPtr)))
                AMGR_trace_zone (found);
        }
    else
        for (curPtr = final; curPtr >= (uintptr_t *)mgr->stkBegin;
             curPtr = (uintptr_t *)(((char *)curPtr) - wordSize))
        {
            if (*curPtr % wordSize)
                continue;
            else if ((found = AMGR_ptr_for_address (*curPtr)))
                AMGR_trace_zone (found);
        }
}

void AMGR_trace_stack_extent ()
{
    jmp_buf env;
    void (*current_extent) (void);

    current_extent =
        (setjmp (env) != UINTPTR_MAX) ? AMGR_trace_terminal_stack_extent : NULL;

    current_extent ();
}

void AMGR_trace_roots ()
{
    zoneTblEnt ** it;
    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
        if ((*it)->root)
            AMGR_trace_zone (*it);
}

void AMGR_trace ()
{
    AMGR_unmark_all_zones ();
    AMGR_trace_stack_extent ();
    AMGR_trace_roots ();
}

/* Sweeping */

void AMGR_delete (zoneTblEnt * toFree)
{
    void * loc;

    if (toFree->tls)
        loc = pthread_getspecific (*(pthread_key_t *)toFree->start);
    else
        loc = toFree->start;

    if (toFree->object)
    {
        [(id)loc ARC_dealloc];
    }
    else
    {

        free (loc);
    }
    if (toFree->tls)
        free (toFree->start);
}

void AMGR_sweep ()
{
    zoneTblEnt ** it = &((Automgr *)ThrdMgr ())->zoneTbl;
    while (*it)
    {
        if (!(*it)->marked && !(*it)->root)
        {
            zoneTblEnt * toFree = *it;
            *it = toFree->next;
            AMGR_delete (toFree);
            AM_free (toFree);
        }
        else
            it = &(*it)->next;
    }
}

void AMGR_cycle ()
{
    if (!ThrdMgr ()->enabled)
        return;
    AMGR_trace ();
    AMGR_sweep ();
}
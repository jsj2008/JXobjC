/*
 * Automgr Tracing GC for JX Objective-C
 * Copyright (c) 2015 D. Mackay. All rights reserved.
 * Use is subject to licence terms.
 */

#include <setjmp.h>
#include <stdint.h>
#include <stdlib.h>

#include "automgr.h"

#define ThrdMgr() pthread_getspecific (mgrForThread)

typedef struct _zoneTblEnt
{
    void * start;
    size_t length;
    /* If it is root, then it is never un-marked.
    * If it is copy, then it is copied for new threads.
    * If it is object, we call its ARC_dealloc routine. */
    BOOL marked, traced, root, copy, object;

    struct _zoneTblEnt * next;
} zoneTblEnt;

typedef struct _Automgr
{
    pthread_mutex_t lock;
    void *stkBegin, *stkEnd;
    zoneTblEnt * zoneTbl;
} Automgr;

static size_t wordSize = sizeof (uintptr_t);
static pthread_key_t mgrForThread;
static pthread_mutexattr_t recursiveAttr;

Automgr * AMGR_init (void * stkBegin)
{
    Automgr * mgr = malloc (sizeof *mgr);
    pthread_mutex_init (&mgr->lock, &recursiveAttr);
    mgr->zoneTbl  = 0;
    mgr->stkBegin = stkBegin;
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
            zoneTblEnt * cpy = malloc (sizeof *cpy);
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
}

void AMGR_main_init (void * stkBegin)
{
    pthread_mutexattr_settype (&recursiveAttr, PTHREAD_MUTEX_RECURSIVE);
    pthread_key_create (&mgrForThread, 0);
    pthread_setspecific (mgrForThread, AMGR_init (stkBegin));
}

void AMGR_add_zone (void * start, size_t length, BOOL isRoot, BOOL isCopy,
                    BOOL isObject)
{
    Automgr * mgr         = ThrdMgr ();
    zoneTblEnt * newEntry = malloc (sizeof *newEntry);

    newEntry->start  = start;
    newEntry->length = length;
    newEntry->root   = isRoot;
    newEntry->copy   = isCopy;
    newEntry->object = isObject;
    newEntry->marked = NO;
    newEntry->traced = NO;

    newEntry->next = mgr->zoneTbl;
    mgr->zoneTbl   = newEntry;
}

void AMGR_remove_zone (void * location)
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it; it = &(*it)->next)
    {
        if ((*it)->start == location)
        {
            zoneTblEnt * toFree = *it;
            *it = toFree->next;
            free (toFree);
            break;
        }
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

/* CStdLib equivalents */

void * AMGR_alloc (size_t bytes)
{
    void * ptr = malloc (bytes);

    AMGR_add_zone (ptr, bytes, NO, NO, NO);

    return ptr;
}

void * AMGR_calloc (size_t num, size_t bytes)
{
    void * ptr = calloc (num, bytes);

    AMGR_add_zone (ptr, num * bytes, NO, NO, NO);

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

void AMGR_sweep () {}

void AMGR_cycle ()
{
    AMGR_trace ();
    AMGR_sweep ();
}
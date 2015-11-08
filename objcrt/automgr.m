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
    BOOL marked, root, copy, object;

    struct _zoneTblEnt * next;
} zoneTblEnt;

typedef struct _Automgr
{
    pthread_mutex_t lock;
    void *stkBegin, *stkEnd;
    zoneTblEnt * zoneTbl;
} Automgr;

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

/* This method will, if `location' matches the address of a zone,
 * mark it.
 * Should this check if location falls within the range of a zone, or
 * just equality? */
void AMGR_ptr_for_address (uintptr_t location)
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
    {
        if ((*it)->start == (void *)location)
        {
            (*it)->marked = YES;
        }
    }
}

void AMGR_unmark_all_zones ()
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
        (*it)->marked = NO;
}

/* Tracing */

void AMGR_trace_terminal_stack_extent ()
{
    Automgr * mgr = ThrdMgr ();
    uintptr_t *final, *curPtr;
    size_t wordSize = sizeof (uintptr_t);
    void * top      = 0;
    final           = (uintptr_t *)&top;

    if (mgr->stkBegin > (void *)final)
        for (curPtr = final; curPtr <= (uintptr_t *)mgr->stkBegin;
             curPtr = (uintptr_t *)(((char *)curPtr) + wordSize))
        {
            if (*curPtr % wordSize)
                continue;
            AMGR_ptr_for_address (*curPtr);
        }
    else
        for (curPtr = final; curPtr >= (uintptr_t *)mgr->stkBegin;
             curPtr = (uintptr_t *)(((char *)curPtr) - wordSize))
        {
            if (*curPtr % wordSize)
                continue;
            AMGR_ptr_for_address (*curPtr);
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

void AMGR_trace () { AMGR_trace_stack_extent (); }

void AMGR_sweep () {}

void AMGR_cycle ()
{
    AMGR_trace ();
    AMGR_sweep ();
}
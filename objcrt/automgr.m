/*
 * Automgr Tracing GC for JX Objective-C
 * Copyright (c) 2015 D. Mackay. All rights reserved.
 * Use is subject to licence terms.
 */

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

void AMGR_init_thrd (void * stkBegin)
{
    Automgr * mgr = malloc (sizeof *mgr);
    pthread_mutex_init (&mgr->lock, &recursiveAttr);
    mgr->zoneTbl  = 0;
    mgr->stkBegin = stkBegin;
    pthread_setspecific (mgrForThread, mgr);
}

void AMGR_main_init (void * stkBegin)
{
    pthread_mutexattr_settype (&recursiveAttr, PTHREAD_MUTEX_RECURSIVE);
    pthread_key_create (&mgrForThread, 0);
    AMGR_init_thrd (stkBegin);
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
void AMGR_ptr_for_address (void * location)
{
    zoneTblEnt ** it;

    for (it = &((Automgr *)ThrdMgr ())->zoneTbl; *it != 0; it = &(*it)->next)
    {
        if ((*it)->start == location)
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
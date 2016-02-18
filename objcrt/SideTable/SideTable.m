/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include <gc.h>
#include <pthread.h>
#include <stdlib.h>

#include "objcrt.h"
#include "dictionary.h"

/* A mapping of object pointers to SideTableEntries. */
static Dictionary_t * sideTable;

/* These are allocated with GC_malloc_uncollectable. */
typedef struct SideTableEntry_s
{
    BOOL lockIsReady;
    pthread_mutex_t lock;
    /* A mapping of iVar names to addresses. */
    Dictionary_t * additional_ivars;
} SideTableEntry;

SideTableEntry * allocSideTableEntry ()
{
    return OC_MallocUncollectable (sizeof (SideTableEntry));
}

INLINE SideTableEntry * sideTableForObject (id anObject, BOOL create)
{
    SideTableEntry * table =
        (SideTableEntry *)Dictionary_get (sideTable, (const char *)anObject);

    if (table)
        return table;
    else if (create)
    {
        table = allocSideTableEntry ();
        Dictionary_set (sideTable, (char *)anObject, (char *)table);
        return table;
    }
    else
        return 0;
}

Dictionary_t * additionalIVarDictionaryForObject (id anObject, BOOL create)
{
    SideTableEntry * sTable = sideTableForObject (anObject, create);

    if (!sTable)
        return 0;
    if (sTable->additional_ivars)
        return sTable->additional_ivars;
    else if (create)
        return (sTable->additional_ivars = Dictionary_new (NO, YES, YES));
    else
        return 0;
}

void * iVarAddressFromSideTable (id anObject, const char * iVarName,
                                 BOOL create)
{
    void * candidate;
    Dictionary_t * additionals =
        additionalIVarDictionaryForObject (anObject, create);

    if (!additionals)
        return 0;

    if ((candidate = (void *)Dictionary_get (additionals, iVarName)))
        return candidate;
    else if (create)
    {
        candidate = OC_Malloc (8);
        Dictionary_set (sideTable, (char *)anObject, (char *)candidate);
        return candidate;
    }
    else
        return 0;
}

pthread_mutex_t * mutexForObject (id anObject)
{
    SideTableEntry * sTable = sideTableForObject (anObject, YES);

    if (!sTable->lockIsReady)
    {
        pthread_mutexattr_t recursiveAttr = {0};
        pthread_mutexattr_settype (&recursiveAttr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init (&sTable->lock, &recursiveAttr);
    }

    return &sTable->lock;
}

void destroySideTableForObject (id anObject)
{
    SideTableEntry * sTable = sideTableForObject (anObject, NO);

    if (!sTable)
        return;

    if (sTable->lockIsReady)
        pthread_mutex_destroy (&sTable->lock);
    if (sTable->additional_ivars)
        Dictionary_delete (sTable->additional_ivars, NO);
    Dictionary_unset (sideTable, sTable, YES);
}

void sideTable_init () { sideTable = Dictionary_new (YES, NO, NO); }

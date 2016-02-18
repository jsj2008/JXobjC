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
    pthread_mutex_t lock;
    /* A mapping of iVar names to addresses. */
    Dictionary_t * additional_ivars;
} SideTableEntry;

void sideTable_init () { sideTable = Dictionary_new (YES, NO, NO); }

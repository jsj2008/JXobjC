/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include <gc.h>
#include <pthread.h>
#include <stdlib.h>

#include "objcrt.h"
#include "Dictionary.h"

static Dictionary_t * sideTable;

/* These are allocated with GC_malloc_uncollectable. */
typedef struct SideTableEntry_s
{
    pthread_mutex_t lock;
    Dictionary_t * additional_ivars;
} SideTableEntry;

void sideTable_init () {}

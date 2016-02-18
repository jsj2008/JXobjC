/*
 * LibSunshine
 *
 * Function & type definitions for dictionary implementation.
 */

#ifndef Dictionary_h
#define Dictionary_h

#ifdef __cplusplus
extern "C" {
#endif

#include <objc-defs.h>
#include <threads.h>
#include "List.h"

typedef struct Dictionary_entry
{
    char * key;
    char * value;
} Dictionary_entry_t;

typedef struct Dictionary
{
    int size;
    int count;
    List_t_ **
        entries; /* array of list_t*s pointing to of dictionary_entry_ts */
    mtx_t * Lock;
    BOOL isAtomic : 1, isCollectable : 1, stringKey : 1;
} Dictionary_t;

#define DICTIONARY_ITERATE_OPEN(DICT)                                          \
    List_t_ *e, *next;                                                         \
    Dictionary_entry_t * entry;                                                \
    mtx_lock ((DICT)->Lock);                                                   \
    for (int i = 0; i < (DICT)->size; i++)                                     \
    {                                                                          \
        for (e = (DICT)->entries[i]; e != 0; e = next)                         \
        {                                                                      \
            next  = e->Link;                                                   \
            entry = e->data;

#define DICTIONARY_ITERATE_CLOSE(DICT)                                         \
    }                                                                          \
    }                                                                          \
    mtx_unlock ((DICT)->Lock);

Dictionary_t * Dictionary_new (BOOL isAtomic, BOOL isCollectable,
                               BOOL stringKey);
void Dictionary_delete (Dictionary_t * dict, BOOL delcontents);
const void * Dictionary_set (Dictionary_t * dict, const char * key,
                             const void * value);
const void * Dictionary_get (Dictionary_t * dict, const char * key);
void Dictionary_unset (Dictionary_t * dict, const char * key, BOOL delvalue);

#ifdef __cplusplus
}
#endif

#endif

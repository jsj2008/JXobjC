/*
 * LibSunshine
 *
 * Implementation of a dictionary.
 */

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "List.h"
#include "Dictionary.h"
#include "objcrt.h"

#define _Lock_Dictionary mtx_lock (dict->Lock);
#define _Unlock_Dictionary mtx_unlock (dict->Lock);

#define _NewAlloc(x)                                                           \
    isCollectable ? (isAtomic ? OC_MallocAtomic (x) : OC_Malloc (x))           \
                  : (isAtomic ? OC_MallocAtomicUncollectable (x)               \
                              : OC_MallocUncollectable (x))
#define _Alloc(x)                                                              \
    dict->isCollectable                                                        \
        ? (dict->isAtomic ? OC_MallocAtomic (x) : OC_Malloc (x))               \
        : (dict->isAtomic ? OC_MallocAtomicUncollectable (x)                   \
                          : OC_MallocUncollectable (x))

/* internal functions */

static unsigned long
jenkins_hash (const char * key) /* Jenkins One-at-a-Time Hash function */
{
    unsigned long int hash;
    size_t len = strlen (key);

    for (int i = hash = 0; i < len; ++i)
    {
        hash += key[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }

    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return hash;
}

#define hashKey(aKey)                                                          \
    dict->stringKey                                                            \
        ? (((13 * (uintptr_t)aKey) ^ ((uintptr_t)aKey >> 15)) % dict->size)    \
        : (jenkins_hash (aKey) % dict->size)

Dictionary_t * Dictionary_new_i (int size, BOOL isAtomic, BOOL isCollectable,
                                 BOOL stringKey);

static Dictionary_t * resize (Dictionary_t * dict)
{
    Dictionary_t * newdict;
    Dictionary_t tmp;
    List_t_ * e;
    Dictionary_entry_t * entry;
    mtx_t * lock = dict->Lock;

    newdict = Dictionary_new_i (dict->size * 2, dict->isAtomic,
                                dict->isCollectable, dict->stringKey);

    for (int i = 0; i < dict->size; i++)
    {
        for (e = dict->entries[i]; e != 0; e = e->Link)
        {
            entry = e->data;
            Dictionary_set (newdict, entry->key, entry->value);
        }
    }

    tmp      = *dict;
    *dict    = *newdict;
    *newdict = tmp;

    Dictionary_delete (newdict, NO);
    dict->Lock = lock;
    return dict;
}

/* primary functions */

Dictionary_t * Dictionary_new_i (int size, BOOL isAtomic, BOOL isCollectable,
                                 BOOL stringKey)
{
    Dictionary_t * newdict = _NewAlloc (sizeof (Dictionary_t));

    newdict->isAtomic      = isAtomic;
    newdict->isCollectable = isCollectable;
    newdict->stringKey     = stringKey;
    newdict->size          = size;
    newdict->entries       = _NewAlloc (sizeof (List_t_ *) * newdict->size);

    newdict->Lock = _NewAlloc (sizeof (mtx_t));
    mtx_init (newdict->Lock, mtx_plain);

    return newdict;
}

Dictionary_t * Dictionary_new (BOOL isAtomic, BOOL isCollectable,
                               BOOL stringKey)
{
    return Dictionary_new_i (32, isAtomic, isCollectable, stringKey);
}

void Dictionary_delete (Dictionary_t * dict, BOOL delcontents)
{
    List_t_ *e, *next;
    Dictionary_entry_t * entry;
    for (int i = 0; i < (dict)->size; i++)
    {
        for (e = (dict)->entries[i]; e != 0; e = next)
        {
            next  = e->Link;
            entry = e->data;
            free (entry->key);
            if (delcontents)
                free (entry->value);
            free (entry);
            free (e);
        }
    }

    free (dict->entries);
    free (dict);
}

const void * Dictionary_set (Dictionary_t * dict, const char * key,
                             const void * value)
{
    Dictionary_entry_t * new, *e;
    List_t_ *lentry, *l;
    unsigned long hash;

    _Lock_Dictionary;

    new    = _Alloc (sizeof (Dictionary_entry_t));
    lentry = _Alloc (sizeof (List_t_));

    new->key   = dict->stringKey ? strdup (key) : (char *)key;
    new->value = (char *)value;

    hash = hashKey (key);

    if ((dict->count + 2) >= dict->size)
    {
        dict = resize (dict);
        assert (dict != 0);
    }

    /* Scan this chain for a matching key that already exists;
     * if one is found, then replace its value. */
    for (l = dict->entries[hash]; l != 0; l = l->Link)
    {
        e = l->data;

        if ((dict->stringKey && !strcmp (e->key, key)) ||
            (!dict->stringKey && e->key == key))
        {
            void * r = e->value;
            e->value = new->value;
            free (new);
            free (lentry);
            _Unlock_Dictionary;
            return r; /* reassigned value of an entry */
        }
    }

    /* Insert this entry into the chain; there was no extant entry found
     * above. */
    {
        lentry->Link        = dict->entries[hash];
        lentry->data        = new;
        dict->entries[hash] = lentry;
        dict->count++;
        _Unlock_Dictionary;
        return 0;
    }
}

const void * Dictionary_get (Dictionary_t * dict, const char * key)
{
    List_t_ * l;
    Dictionary_entry_t * e;

    _Lock_Dictionary

        for (l = dict->entries[hashKey (key)]; l != 0; l = l->Link)
    {
        e = l->data;

        if (!strcmp (e->key, key))
        {
            _Unlock_Dictionary return e->value;
        }
    }

    _Unlock_Dictionary return 0;
}

void Dictionary_unset (Dictionary_t * dict, const char * key, BOOL del)
{
    List_t_ ** p;
    List_t_ * e;
    Dictionary_entry_t * entry;

    _Lock_Dictionary

        for (p = &(dict->entries[hashKey (key)]); *p != 0; p = &((*p)->Link))
    {

        entry = (*p)->data;

        if (!strcmp (entry->key, key))
        {
            e  = *p;
            *p = e->Link;

            if (dict->stringKey)
                ;
            free (entry->key);
            if (del)
                free (entry->value);
            free (entry);
            free (e);
            _Unlock_Dictionary

                return;
        }
    }
    _Unlock_Dictionary
}

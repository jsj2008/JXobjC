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
#include <string.h>

#ifdef OBJC_REFCNT
#pragma OCRefCnt 0 /* if compiled with -refcnt, turn of refcnt now */
#endif

#include "objcrt.h"

#define SIZEHASHTABLE 73 /* default initial size */

static PHASH * hashList;
static int nHashLists;

static SEL minsel, maxsel;

static BOOL isminmaxsel (SEL s) { return (minsel <= s) && (s <= maxsel); }

/*****************************************************************************
 *
 * Hash Table Maintenance
 *
 * Selectors are uniqued strings.
 *
 ****************************************************************************/

int strCmp (char * s1, char * s2)
{
    int r;
    int c1, c2;

    while (1)
    {
        c1 = *s1++;
        c2 = *s2++;
        if (c1 == '\0')
            return (c2 == 0) ? 0 : -1;
        if (c2 == '\0')
            return 1;
        if ((r = c1 - c2))
            return r;
    }
}

unsigned strHash (char * s)
{
    unsigned hash = 0;

    while (1)
    {
        if (*s == '\0')
            break;
        else
            hash ^= *s++;
        if (*s == '\0')
            break;
        else
            hash ^= (*s++ << 8);
        if (*s == '\0')
            break;
        else
            hash ^= (*s++ << 16);
        if (*s == '\0')
            break;
        else
            hash ^= (*s++ << 24);
    }

    return hash;
}

void hashInit ()
{
    int i;
    nHashLists = SIZEHASHTABLE;

    hashList = (PHASH *)malloc (nHashLists * sizeof (PHASH));

    for (i = 0; i < nHashLists; i++)
        hashList[i] = 0;
}

PHASH hashNew (STR key, PHASH link)
{
    int n;
    PHASH obj;
    assert (key != NULL);
    obj       = (PHASH)malloc (sizeof (HASH));
    obj->next = link;
    n         = strlen (key);
    obj->key = (STR)malloc (n + 1);
    strcpy (obj->key, key);
    return obj;
}

PHASH search (STR key, long * slot, PHASH * prev)
{
    PHASH target;

    *slot  = strHash (key) % nHashLists;
    *prev  = 0;
    target = hashList[*slot];

    while (target && (strCmp (key, target->key) != 0))
    {
        *prev  = target;
        target = target->next;
    }

    return target;
}

PHASH hashEnter (STR key, long slot)
{
    assert (key != NULL);
    if (minsel)
    {
        if (key < minsel)
            minsel = key;
        if (key > maxsel)
            maxsel = key;
    }
    else
    {
        minsel = key;
        maxsel = key;
    }
    if (slot < 0)
        slot       = strHash (key) % nHashLists;
    hashList[slot] = hashNew (key, hashList[slot]);
    return hashList[slot];
}

PHASH hashLookup (STR key, long * slot)
{
    PHASH prev;
    return search (key, slot, &prev);
}

/*****************************************************************************
 *
 * Conversion String, Selector, Class
 *
 ****************************************************************************/

STR EXPORT selName (SEL sel)
{
    if (isminmaxsel (sel))
    {
        return (STR) (sel); /* trivial for our runtime */
    }
    else
    {
        return NULL;
    }
}

SEL EXPORT selUid (STR sel)
{
    long slot;
    PHASH retVal;
    if ((retVal = hashLookup (sel, &slot)))
        return (SEL)retVal->key;
    return NULL;
}

static SEL cvtToSel (STR aString)
{
    if (aString == NULL)
        return NULL;
    return selUid (aString);
}

static SEL cvtAsSel (STR aString)
{
    PHASH retVal;
    long slot;

    if (!(retVal = hashLookup (aString, &slot)))
        retVal = hashEnter (aString, slot);

    return retVal->key;
}

/* for cplusplus the (STR) cannot be () */
SEL (*JX_cvtToSel) (STR) = cvtToSel;
SEL (*JX_cvtAsSel) (STR) = cvtAsSel;
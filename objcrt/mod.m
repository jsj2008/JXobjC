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

#ifdef OBJC_REFCNT
#pragma OCRefCnt 0 /* if compiled with -refcnt, turn of refcnt now */
#endif

#include <stdlib.h>
#include <string.h>

#include "objcrt.h"
#include "objc-memory.h"
#include "access.h"
#include "seltab.h"
#include "mod.h"
#include "ivar.h"

#include "OutOfMem.h"

static void markmodmapped (struct objcrt_modDescriptor * aMod)
{
    (aMod)->modStatus |= MOD_MAPPED;
}

static BOOL morethanone (struct objcrt_modDescriptor * aMod)
{
    return (aMod)->modStatus & MOD_MORETHANONE; /* TRUE for 1.4.x */
}

/* _objcModules is defined as NULL for auto-initialization
 * it's defined as the table of BIND functions that need to be called
 * in the postlink version
 */

/* defining _objcModules as "extern" (as it should) will break
 * compiler-recompiles using < 1.1.6 bootstrap compilers (because these
 * compilers don't emit an _objcModules definition).
 */

/* 11/97 _objcModules not defined at all any more for Windows NT DLL's !
 * (NOSHARED case)
 */

#ifndef OBJCRT_NOSHARED
extern Mentry_t _objcModules;
#endif

/* List for when loading shared objects (using dlopen() or similar)
 * and then calling loadobjc() on that _objcModules array.
 */
typedef struct modnode
{
    Mentry_t objcmodules;
    struct modnode * next;
} * modnode_t;

static modnode_t modnodelist;

static modnode_t newmodnode (Mentry_t me, modnode_t next)
{
    modnode_t r;
    r              = (modnode_t)OC_Malloc (sizeof (struct modnode));
    r->next        = next;
    r->objcmodules = me;
    return r;
}

static void freemodnode (modnode_t * n, modnode_t m)
{
    *n = m->next;
    OC_Free (m);
}

static void mapsels (PMOD info, SEL * sel)
{
    PHASH ent;
    long i, slot;

    for (i = 0; i < info->modSelRef; i++)
    {
        SEL k;

        if (!(ent = hashLookup (info->modSelTbl[i], &slot)))
        {
            ent = hashEnter (info->modSelTbl[i], slot);
        }

        k = ent->key;

        if (sel != 0 && *sel == info->modSelTbl[i])
        {
            *sel = k;
        }

        /* 'unique' the string (replace by shared one) */
        info->modSelTbl[i] = k;
    }

    /* mark module as mapped */
    markmodmapped (info);
}

static void mapcls (Cls_t cls)
{
    PHASH ent;
    long i, slot;

    for (i = 0; i < cls->clsSizDict; i++)
    {
        if (!(ent = hashLookup (cls->clsDispTable[i]._cmd, &slot)))
        {
            ent = hashEnter (cls->clsDispTable[i]._cmd, slot);
        }

        /* unique string */
        cls->clsDispTable[i]._cmd = ent->key;
    }

    markmapped (cls);
}

static void mapclass (Cls_t cls)
{
    if (!ismapped (cls))
        mapcls (cls);

    /* also do the meta */
    while (isfactory (cls))
    {
        cls = getmeta (cls);
        if (!ismapped (cls))
            mapcls (cls);
    }
}

/*****************************************************************************
 *
 * Runtime Initialization
 *
 ****************************************************************************/

static BOOL objcinitflag; /* YES after initialization */

BOOL _objcinitflag () { return objcinitflag; }

/*
 *  Modlist is the handle of a linked list of modules with _BIND
 *  entries found so far.  Since the order of entries is not
 *  important, it can be maintained efficiently with only a single
 *  pointer.
 */
static struct objcrt_useDescriptor * modlist = 0;
static int bindcnt                           = 0; /* _BIND entries found so far */

#ifndef OBJCRT_NOSHARED
extern struct objcrt_useDescriptor * OCU_main; /* entry point for the program */
#endif

/*
 *  Recursively process each of the module use descriptors
 */

static void traverse (struct objcrt_useDescriptor * desc)
{
    struct objcrt_useDescriptor *** nxt;

    /*  Mark this one as processed to break any cycles */
    desc->processed = 1;

    /* process each of the pointers in turn */
    for (nxt = desc->uses; *nxt; nxt++)
    {
        if (**nxt && !((**nxt)->processed))
            traverse (**nxt);
    }

    /*
     *  If this module has a bind entry point, add it to the linked
     *  list of modules with bind entries and increment the count of
     *  modules with bind entries that have been processed.
     */
    if (desc->bind)
    {
        desc->next = modlist;
        modlist    = desc;
        bindcnt++;
    }
}

static Mentry_t findmods (struct objcrt_useDescriptor * desc)
{
    Mentry_t tmp;
    unsigned aSize;
    Mentry_t theModules;
    struct objcrt_useDescriptor * md;

    if (desc && !(desc->processed))
        traverse (desc);

    aSize      = (bindcnt + 1) * sizeof (struct objcrt_modEntry);
    theModules = (Mentry_t)OC_Malloc (aSize);

    /*
     *  initialize it with the entries we have just found
     */
    for (md = modlist, tmp = theModules; md; md = md->next, tmp++)
    {
        tmp->modLink = md->bind;
        tmp->modInfo = 0;
    }

    /* initsels() depends on modLink of last element null'ed */
    tmp->modLink = 0;
    tmp->modInfo = 0;

    return theModules;
}

static void initsels (Mentry_t modPtr)
{
    static int needHashInit = 1;

    /* we can get here from _objcInit() or from loadobjc()
     * for some shared library that gets loaded _before_ the main()
     */
    if (needHashInit)
    {
        hashInit ();
        needHashInit = 0;
    }

    for (; modPtr && modPtr->modLink; modPtr++)
    {
        PMOD info = modPtr->modInfo = (*modPtr->modLink) ();

        if (info)
        {
            id * cls;

            if (info->modSelTbl)
                mapsels (info, 0);

            cls = modPtr->modInfo->modClsLst;

            if (morethanone (modPtr->modInfo))
            {
                while (*cls)
                    mapclass (getcls (*cls++));
            }
            else
            {
                if (cls)
                    mapclass (getcls (*cls));
            }
        }
    }
}

void initcls (id cls)
{
    Cls_t aCls = getcls (cls);

    if (initlzd (aCls))
        return;

    ClassIVarsTotalOffset (cls, YES);
    ClassSetIVarAccessorVars (cls, (Cls_t)nil, 0);

#ifdef OBJC_REFCNT
    if (!isrefcntclass (aCls))
    {
        char * msg =
            "Classes compiled with and without -refcnt cannot be mixed.";
        report (nil, msg);
    }
#endif

    /* force initialization of superclasses first */
    /* if we're a category, this will also force initialization of class */
    /* (which is just the superclass) */
    if (aCls->clsSuper)
    {
        initcls (aCls->clsSuper);
    }

    /* It's possible my superclass has sent a message back to me
     * from its 'initialize' method, which has caused me to get
     * initlzd! Check again.
     */
    if (initlzd (aCls))
        return;

    markinitlzd (aCls);

    if (iscatgry (aCls))
    {
        addMethods (cls, aCls->clsSuper);
    }

    [cls initialize];
}

static void initmods (Mentry_t modPtr)
{
    for (; modPtr->modInfo; modPtr++)
    {
        id * cls = modPtr->modInfo->modClsLst;

        if (morethanone (modPtr->modInfo))
        {
            while (*cls)
            {
                initcls (*cls);
                cls++;
            }
        }
        else
        {
            if (cls && *cls)
            {
                initcls (*cls);
            }
        }
    }
}

/*
 * The init function should not be prototyped in a header, but should match
 * the init call emitted by compiler.
 *
 * Some systems have an _objcInit() in their system libs, so use some other
 * name in these cases.
 *
 * Traditionally, _objcInit() was getting its modules from a global
 * _objcModules.  In the NOSHARED case, we use the _objcInitNoShared() call
 * instead.
 */
static void msgiods (void)
{
    STR s;

    /* this is not a constant on cygwin32 */
    dbgIOD = stderr;
    if ((s = (getenv ("OBJCRTDBG"))))
    {
        dbgFlag = YES;
        if (strcmp (s, "stderr") == 0)
        {
            dbgIOD = stderr;
        }
        else
        {
            dbgIOD = fopen (s, "w");
            setbuf (dbgIOD, NULL);
        }
    }

    msgIOD = stderr;
    if ((s = (getenv ("OBJCRTMSG"))))
    {
        msgFlag = YES;
        if (strcmp (s, "stderr") == 0)
        {
            msgIOD = stderr;
        }
        else
        {
            msgIOD = fopen (s, "w");
            /* if both dbgFlag and msgFlag, unbuffer */
            /* large amounts of output, so prefer block buffer */
            if (dbgFlag)
                setbuf (msgIOD, NULL);
        }
    }
}

int EXPORT JX_objcInitNoShared (Mentry_t _objcModules,
                                struct objcrt_useDescriptor * OCU_main)
{
    modnode_t m;

    if (objcinitflag)
    {
        return 1;
    }
    else
    {
        msgiods ();

        pthread_mutex_init (&cLock, NULL);
        pthread_spin_init (&rcLock, PTHREAD_PROCESS_SHARED);

        sideTable_init ();

        /* Do auto-initialisation if _objcModules is zero.  Otherwise,
         * assume that it is the list of all bind functions to be called.
         */
        if (!_objcModules)
            _objcModules = findmods (OCU_main);

        loadobjc (_objcModules);

        /* Do initialisation of modules that were already registered
         * via shlibs that got loaded before _objcInit().
         * First, call all BIND functions (including OBJCBIND_objcrt!)
         * then start sending +initialize messages.
         */
        for (m = modnodelist; m; m = m->next)
            initsels (m->objcmodules);
        for (m = modnodelist; m; m = m->next)
            initmods (m->objcmodules);

        /* initialize the Malloc exception blocks cause we can't allocate
           * them when we run out of memory !
           * This must be done after initializing the runtime
         */
        outOfMem = [OutOfMemory new];

        /* finished _objcInit(). it's now safe for loadobjc() to
         * call initobjc()
         */
        objcinitflag = YES;

        /* Stepstone objcc returns maxSelector, probably not used */
        return 0;
    }
}

/* traditional entry point _objcInit, or prefixed entry point oc_objcInit
 * when we have to live together with another runtime
 */

#ifndef OBJCRT_NOSHARED
int EXPORT oc_objcInit (int debug, BOOL traceInit)
{
    return JX_objcInitNoShared (_objcModules, OCU_main);
}
#endif

/*****************************************************************************
 *
 * Conversion String, Selector, Class
 *
 ****************************************************************************/

static id cvtToId (STR aClassName)
{
    modnode_t m;
    Mentry_t modPtr;

    if (aClassName == NULL)
        return nil;

    for (m = modnodelist; m; m = m->next)
    {
        for (modPtr = m->objcmodules; modPtr && modPtr->modLink; modPtr++)
        {
            id * cls;
            Cls_t aCls;

            cls = modPtr->modInfo->modClsLst;

            if (morethanone (modPtr->modInfo))
            {
                while (*cls)
                {
                    aCls = getcls (*cls);
                    if (strCmp (aCls->clsName, aClassName) == 0)
                    {
                        return *cls;
                    }
                    cls++;
                }
            }
            else
            {
                if (cls)
                {
                    aCls = getcls (*cls);
                    if (strCmp (aCls->clsName, aClassName) == 0)
                        return *cls;
                }
            }
        }
    }

    return nil;
}

id (*JX_cvtToId) (STR) = cvtToId;

/*****************************************************************************
 *
 * Finding subclasses.
 *
 ****************************************************************************/

static BOOL issubclass (Cls_t aCls, STR aClassname)
{
    if (aCls->clsSuper)
    {
        Cls_t clsSuper = getcls (aCls->clsSuper);
        return strCmp (clsSuper->clsName, aClassname) == 0;
    }
    else
    {
        return 0;
    }
}

void addSubclassesTo (id c, STR aClassname)
{
    modnode_t m;
    Mentry_t modPtr;

    for (m = modnodelist; m; m = m->next)
    {
        for (modPtr = m->objcmodules; modPtr && modPtr->modLink; modPtr++)
        {
            id * cls;
            Cls_t aCls;

            cls = modPtr->modInfo->modClsLst;

            if (morethanone (modPtr->modInfo))
            {
                while (*cls)
                {
                    aCls = getcls (*cls);
                    if (issubclass (aCls, aClassname))
                        [c add:*cls];
                    cls++;
                }
            }
            else
            {
                if (cls)
                {
                    aCls = getcls (*cls);
                    if (issubclass (aCls, aClassname))
                        [c add:*cls];
                }
            }
        }
    }
}

static PMOD newModDesc (id * clsLst)
{
    PMOD mod = (PMOD)OC_Malloc (sizeof (MOD));

    mod->modName = "dynamic";
    mod->modName = "2.3.15";
    /* not MOD_MORETHANONE (clsLst is not NULL terminated, it's just 1 class) */
    mod->modStatus = 0;
    mod->modMinSel = NULL;
    mod->modMaxSel = NULL;
    mod->modClsLst = clsLst;
    mod->modSelRef = 0;
    mod->modSelTbl = NULL;
    mod->modMapTbl = NULL;

    return mod;
}

static PMOD dynMod; /* ugh - hack to communicate between dynBind and addMod */
static PMOD dynBIND (void) { return dynMod; }

static void addModEntry (id aCls)
{
    id * clsLst;
    Mentry_t entry, sentin;
    entry = (Mentry_t)OC_Malloc (2 * sizeof (struct objcrt_modEntry));

    clsLst  = OC_Malloc (sizeof (id));
    *clsLst = aCls;
    dynMod  = newModDesc (clsLst);

    entry->modLink = dynBIND;
    entry->modInfo = NULL;

    /* initsels depends on sentinel */
    sentin          = entry + 1;
    sentin->modLink = NULL;
    sentin->modInfo = NULL;

    loadobjc (entry); /* dynBIND will use dynMod */
}

void linkclass (id aclass) { addModEntry (aclass); }

void unlinkclass (id aclass)
{
    modnode_t m;
    Mentry_t modPtr;

    if (aclass == nil)
        return;

    for (m = modnodelist; m; m = m->next)
    {
        for (modPtr = m->objcmodules; modPtr && modPtr->modLink; modPtr++)
        {
            id * cls;

            cls = modPtr->modInfo->modClsLst;

            if (morethanone (modPtr->modInfo))
            {
                while (*cls)
                {
                    if (*cls == aclass)
                    {
                        unloadobjc (modPtr);
                        return;
                    }
                    cls++;
                }
            }
            else
            {
                if (cls)
                {
                    if (*cls == aclass)
                    {
                        unloadobjc (modPtr);
                        return;
                    }
                }
            }
        }
    }
}

void _mod_poseAs (id iposing, id itarget)
{
    modnode_t m;
    Mentry_t modPtr;
    Cls_t posing = getcls (iposing);

    /* Now patch the hierarchy;  look for subclasses of 'target'
     * and (if != posing) make their clsSuper point to posing.
     */
    for (m = modnodelist; m; m = m->next)
    {
        for (modPtr = m->objcmodules; modPtr && modPtr->modLink; modPtr++)
        {
            id * cls;
            Cls_t aCls;

            cls = modPtr->modInfo->modClsLst;

            if (morethanone (modPtr->modInfo))
            {
                while (*cls)
                {
                    aCls = getcls (*cls++);
                    if (aCls == posing)
                        continue;
                    if (aCls->clsSuper == itarget)
                    {
                        aCls->clsSuper = iposing;
                        getmeta (aCls)->clsSuper = posing->isa;
                    }
                }
            }
            else
            {
                if (cls)
                {
                    aCls = getcls (*cls);
                    if (aCls == posing)
                        continue;
                    if (aCls->clsSuper == itarget)
                    {
                        aCls->clsSuper = iposing;
                        getmeta (aCls)->clsSuper = posing->isa;
                    }
                }
            }
        }
    }
}

/*
 * This function can be called to add/remove modules to the runtime.
 * (dynamically loaded modules for instance)
 */

static void initobjc (Mentry_t modPtr)
{
    initsels (modPtr);
    initmods (modPtr);
}

void EXPORT loadobjc (void * p)
{
    Mentry_t modPtr = (Mentry_t)p;

    if (!modPtr)
        report (nil, "loadobjc with NULL argument");

    /* check whether we're being called from a shlib that gets loaded
     * _before_ objcInit() has been executed; in this case we want to
     * delay adding the classes, since most likely superclasses (such
     * as Object) are not yet loaded.
     *
     * We simply remember the modules, and main()'s _objcInit() will
     * take care of those.
     */

    modnodelist = newmodnode (modPtr, modnodelist);

    if (!objcinitflag)
    {
        return;
    }
    else
    {
        initobjc (modPtr);
        return;
    }
}

void EXPORT unloadobjc (void * p)
{
    modnode_t m, *n;
    Mentry_t modPtr = (Mentry_t)p;

    if (!modPtr)
        report (nil, "unloadobjc with NULL argument");

    for (n = (&modnodelist), m = (*n); m; m = (*n))
    {
        if (modPtr == m->objcmodules)
        {
            freemodnode (n, m);
            flushCache ();
            return;
        }
        else
        {
            n = &(m->next);
        }
    }

    [Object error:"unloadobjc() for module that is not loaded."];
}

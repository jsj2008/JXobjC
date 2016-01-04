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
#include <string.h> /* memset */

#include <pthread.h> /* POSIX 1003.1c thread-safe messenger */
pthread_spinlock_t rcLock;
static pthread_mutex_t cLock;
static pthread_mutexattr_t recursiveAttr;

#include "Object.h"
#include "Block.h"    /* blockRaise */
#include "Exceptn.h"  /* signal exceptions */
#include "OutOfMem.h" /* signal exceptions */
#include "Message.h"  /* selector:args: */

#include "objc-access.h"
#include "objc-memory.h"

@protocol FinalisableObject
- finalise;
@end

pthread_mutex_t * allocMtx ()
{
    pthread_mutex_t * mutx = malloc (sizeof (pthread_mutex_t));

    pthread_mutexattr_settype (&recursiveAttr, PTHREAD_MUTEX_RECURSIVE);
#if 0
	pthread_mutexattr_setrobust (&recursiveAttr, PTHREAD_MUTEX_ROBUST);
#endif
    pthread_mutex_init (mutx, &recursiveAttr);

    return mutx;
}

#ifdef OBJC_REFCNT
#pragma OCRefCnt 0 /* if compiled with -refcnt, turn of refcnt now */
#endif

#define SIZEHASHTABLE 73 /* default initial size */

static PHASH * hashList;
static int nHashLists;

#if 0
static BOOL 
ismodmapped (struct objcrt_modDescriptor *aMod)
{
  return (aMod)->modStatus & MOD_MAPPED;
}
#endif

static void markmodmapped (struct objcrt_modDescriptor * aMod)
{
    (aMod)->modStatus |= MOD_MAPPED;
}

static BOOL morethanone (struct objcrt_modDescriptor * aMod)
{
    return (aMod)->modStatus & MOD_MORETHANONE; /* TRUE for 1.4.x */
}

static SEL minsel, maxsel;

static BOOL isminmaxsel (SEL s) { return (minsel <= s) && (s <= maxsel); }

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

/* list for when loading shared objects (using dlopen() or similar)
 * and then calling loadobjc() on that _objcModules array
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

/*****************************************************************************
 *
 * Error Handler
 *
 * Especially useful to be declared as a 'function vector' so that the handler
 * can be replaced at runtime by something else.
 *
 ****************************************************************************/

static id reportv (id self, STR fmt, OC_VA_LIST ap)
{
    fflush (stderr);
    prnstack (stderr);
    fprintf (stderr, "error: ");
    vfprintf (stderr, fmt, ap);
    fprintf (stderr, "\n");
    abort ();
    return self;
}

static id report (id self, STR fmt, ...)
{
    OC_VA_LIST ap;
    /* use OC macros here for porting to SunOS4 */
    OC_VA_START (ap, fmt);
    reportv (self, fmt, ap);
    OC_VA_END (ap);
    return self;
}

id (*JX_error) (id self, STR fmt, OC_VA_LIST ap) = reportv;

/*****************************************************************************
 *
 * Default Filer Functions
 *
 * They don't do anything, they just tell the programmer to use AsciiFiler.
 *
 ****************************************************************************/

static void nofiler (void)
{
    [Object error:"No filer class linked into application."];
}

static id readfilein (STR aFileName)
{
    FILE * f;
    id r = nil;
    if ((f = fopen (aFileName, "r")))
    {
        r = (*JX_fileIn) (f);
        fclose (f);
    }
    return r;
}

static BOOL storefileout (STR aFileName, id anObject)
{
    FILE * f;
    BOOL r = NO;
    if ((f = fopen (aFileName, "w")))
    {
        r = (*JX_fileOut) (f, anObject);
        fclose (f);
    }
    return r;
}

static id nofilein (FILE * f)
{
    nofiler ();
    return nil;
}
static BOOL nofileout (FILE * f, id anObject)
{
    nofiler ();
    return NO;
}

id (*JX_fileIn) (FILE *) = nofilein;
id (*JX_readFrom) (STR) = readfilein;
BOOL (*JX_fileOut) (FILE *, id) = nofileout;
BOOL (*JX_storeOn) (STR, id) = storefileout;

/* functions are necessary to do this on Windows (with DLLs) */

void EXPORT setfilein (id (*f) (FILE *)) { JX_fileIn = f; }
void EXPORT setfileout (BOOL (*f) (FILE *, id)) { JX_fileOut = f; }

/* function scoped extern since it can be useful from within debugger
 * in particular if it's not easy to send the |show| message from the debugger
 */

id EXPORT __showOn (id self, unsigned level /* unused */)
{
    (*JX_fileOut) (stderr, self);
    return nil;
}

id (*JX_showOn) (id, unsigned) = __showOn;

/*****************************************************************************
 *
 * Hash Table Maintenance
 *
 * Selectors are uniqued strings.
 *
 ****************************************************************************/

static int strCmp (char * s1, char * s2)
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

static unsigned strHash (char * s)
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

static void hashInit ()
{
    int i;
    nHashLists = SIZEHASHTABLE;

    hashList = (PHASH *)malloc (nHashLists * sizeof (PHASH));

    for (i = 0; i < nHashLists; i++)
        hashList[i] = 0;
}

static PHASH hashNew (STR key, PHASH link)
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

static PHASH search (STR key, long * slot, PHASH * prev)
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

static PHASH hashEnter (STR key, long slot)
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

static PHASH hashLookup (STR key, long * slot)
{
    PHASH prev;
    return search (key, slot, &prev);
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

/*
 *  modlist is the handle of a linked list of modules with _BIND
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

static void initcls (id cls)
{
    Cls_t aCls = getcls (cls);

    if (initlzd (aCls))
        return;

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

    pthread_mutex_init (&cLock, NULL);
    pthread_spin_init (&rcLock, PTHREAD_PROCESS_SHARED);
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

        /* Do auto-initialize if _objcModules is zero.  Otherwise,
           * assume that it is the list of all bind functions to be called
         */

        if (!_objcModules)
            _objcModules = findmods (OCU_main);
        loadobjc (_objcModules);

        /* do initialize of modules that were already registered
         * via shlibs that got loaded before _objcInit()
         * first call all BIND functions (including OBJCBIND_objcrt!)
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

/* for cplusplus the (STR) cannot be () */
id (*JX_cvtToId) (STR) = cvtToId;
SEL (*JX_cvtToSel) (STR) = cvtToSel;

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

/*****************************************************************************
 *
 * Allocation of Classes (Dynamic Subclassing)
 *
 ****************************************************************************/

static id newShared (int aSize) { return (id)OC_Malloc (aSize); }

static id newMeta (STR name, id superClass, int esize)
{
    id m;
    Cls_t n;

    m = newShared (sizeof (struct objcrt_shared));
    n = getcls (m);

    n->isa            = getcls (superClass)->isa; /* isa of meta is root class */
    n->clsSuper       = superClass;
    n->clsName        = name; /* strdup ? */
    n->clsTypes       = getcls (superClass)->clsTypes;
    n->clsSizInstance = getcls (superClass)->clsSizInstance + esize;
    n->clsSizDict     = 0;
    n->clsDispTable   = NULL;
    n->clsStatus      = 0;
    n->clsMod         = NULL; /* unused anyhow */
    n->clsVersion     = getcls (superClass)->clsVersion;
    n->clsGlbl        = NULL;

    return m;
}

static id newClass (STR name, id superClass, int eisize, int ecsize)
{
    id m, meta;
    Cls_t n, c;

    meta = newMeta (name, getcls (superClass)->isa, ecsize);
    m    = newShared (getcls (meta)->clsSizInstance); /* includes cvars */
    n    = getcls (m);
    c    = getcls (superClass);

    n->isa            = meta;
    n->clsSuper       = superClass;
    n->clsName        = name; /* strdup ? */
    n->clsTypes       = c->clsTypes;
    n->clsSizInstance = c->clsSizInstance + eisize;
    n->clsSizDict     = 0;
    n->clsDispTable   = NULL;
    n->clsStatus      = 0;
    n->clsMod         = NULL; /* unused anyhow */
    n->clsVersion     = c->clsVersion;
    n->clsGlbl        = NULL; /* could set this to clsLst */

    return m;
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

id newsubclass (STR name, id superClass, int ivars, int cvars)
{
    return newClass (name, superClass, ivars, cvars);
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

/*****************************************************************************
 *
 * Message Errors & Diagnostics
 *
 ****************************************************************************/

/*
 * This function is used when the selTransTbl table (for selector lookup)
 * is not initialized. (Checked for every selector, not enabled by default).
 */

char EXPORT * objcrt_bindError (char * m)
{
    fprintf (stderr, "objcrt initialization error (_OBJCBIND_%s)", m);
    return NULL;
}

static void prnframe (FILE * f, id obj, SEL sel, BOOL isSuper)
{
    char *nam, *fac;

    if (obj)
    {
        Cls_t cls = getcls (getisa (obj));
        nam       = cls->clsName;
        fac       = (ismeta (cls)) ? "+" : "-";
    }
    else
    {
        nam = "nil";
        fac = "";
    }

    fprintf (f, (isSuper ? "%s\t%s%s\tsuper\n" : "%s\t%s%s\n"), nam, fac, sel);
}

static id _errHandler (id self, SEL sel)
{
    if (sel == @selector (doesNotRecognize:))
    { /* possible ! */
        char * msg;
        msg = "Completely messed up: Object does not recognize "
              "-doesNotRecognize:";
        return report (self, msg);
    }
    else
    {
        return [self doesNotRecognize:sel];
    }
}

static id _nofwdHandler (id self, SEL sel)
{
    return report (self, "'%s': This type of message cannot be forwarded.",
                   sel);
}

static id _freedHandler (id self, SEL sel)
{
    return report (self, "Message '%s' sent to freed object.", sel);
}

/* stes - feb 12, 97 - scoped extern for inlineCache messenger */
/* stes - sep 4, 97 - implemented noNilRcvr option */

BOOL noNilRcvr = NO;

id EXPORT _nilHandler (id self, SEL sel)
{
    return ((noNilRcvr) ? report (self, "Message '%s' sent to nil.", sel)
                        : nil);
}

/*****************************************************************************
 *
 * C Messenger
 *
 * The name "C" messenger comes from the fact that this messenger is
 * implemented in "pure C".  It does not depend on small, auxiliary routines
 * for "building stackframes", usually written in assembler.
 *
 ****************************************************************************/

#define CACHESIZE 1031 /* a prime number */

static id clsCache[CACHESIZE];
static SEL selCache[CACHESIZE];
static TYP typCache[CACHESIZE];
static IMP impCache[CACHESIZE];

static void flushCache (void)
{
    int i = 0;
    for (i = 0; i < CACHESIZE; i++)
        clsCache[i] = nil;
}

FILE * msgIOD;
BOOL msgFlag     = NO;
BOOL noCacheFlag = NO;
BOOL dbgFlag     = NO;
BOOL allocFlag   = NO;
FILE * dbgIOD;

#define CACHE_LOCK pthread_mutex_lock (&cLock);
#define CACHE_UNLOCK pthread_mutex_unlock (&cLock);

/*
 * computing index of IMP pointer in method look-up cache
 * this is done in the _imp() and _impSuper() functions
 * with hopefully a cache hit, and for a cache miss, passed
 * as argument to the _getImp() which does a linear search.
 */

#define CACHE_INDEX(aSel, aShr)                                                \
    (int) ((((unsigned long)aSel) ^ ((unsigned long)aShr)) % CACHESIZE)

static IMP _getImp (id cls, SEL sel, int index, IMP fwd)
{
    Cls_t wCls;
    id ncls = cls; /* working class */

    do
    {
        long n;
        struct objcrt_slt * smt;

        wCls = getcls (ncls);
        smt  = wCls->clsDispTable;

        for (n = 0; n < wCls->clsSizDict; n++, smt++)
        {
            /* selectors can be compared with '==' */
            if (sel == smt->_cmd)
            {
                if (noCacheFlag)
                {
                    return smt->_imp;
                }
                else
                {
                    IMP imp = smt->_imp;
                    TYP typ = smt->_typ;
                    CACHE_LOCK
                    selCache[index] = sel;
                    typCache[index] = typ;
                    clsCache[index] = cls;
                    impCache[index] = imp;
                    CACHE_UNLOCK
                    return imp;
                }
            }
        }
    } while ((ncls = wCls->clsSuper));

    if (objcinitflag)
    {
        return (fwd) ? fwd : _nofwdHandler;
    }
    else
    {
        return _errHandler;
    }
}

/* AIX cc doesnt like & address operator in front of address specs
 * so don't use &_nilHandler.
 *
 * stes 6/13/1998 - changed _imp to the forwarding messenger fwdimp
 * the old _imp can be defined in terms of fwdimp.
 */

IMP EXPORT _imp (id aRecvr, SEL aSel)
{
    return fwdimp (aRecvr, aSel, (IMP)_errHandler);
}

IMP EXPORT _impSuper (id aRecvr, SEL aSel)
{
    return fwdimpSuper (aRecvr, aSel, (IMP)_errHandler);
}

IMP EXPORT fwdimp (id aRecvr, SEL aSel, IMP fwd)
{
    id shr;
    int index;
    Cls_t wCls;
    BOOL inSuper = NO;

    if (msgFlag)
        prnframe (msgIOD, aRecvr, aSel, inSuper);
    if (!aRecvr)
        return (IMP)_nilHandler;
    shr = getisa (aRecvr);
    if (!shr)
        return (IMP)_freedHandler;

    /* try cache hit before extra function call _getImp() */
    index = CACHE_INDEX (aSel, shr);

    if (!noCacheFlag)
    {
        CACHE_LOCK
        if (clsCache[index] == shr && selCache[index] == aSel)
        {
            IMP imp = impCache[index];
            CACHE_UNLOCK return imp;
        }
        CACHE_UNLOCK
    }

    /* it can happen, for msgs sent from within +initialize,
     * that we have to force an +initialize */

    if (ismeta ((wCls = getcls (shr))))
    {
        if (!initlzd (wCls))
            initcls (aRecvr);
    }
    else
    {
        if (!initlzd (wCls))
            initcls (shr);
    }

    return _getImp (shr, aSel, index, fwd);
}

IMP EXPORT fwdimpSuper (id aClass, SEL aSel, IMP fwd)
{
    int index;
    BOOL inSuper = YES;

    if (msgFlag)
        prnframe (msgIOD, aClass, aSel, inSuper);
    if (!aClass)
        return (IMP)_nilHandler;

    /* try cache hit before extra function call _getImp() */
    index = CACHE_INDEX (aSel, aClass);

    if (!noCacheFlag)
    {
        CACHE_LOCK
        if (clsCache[index] == aClass && selCache[index] == aSel)
        {
            IMP imp = impCache[index];
            CACHE_UNLOCK return imp;
        }
        CACHE_UNLOCK
    }

    return _getImp (aClass, aSel, index, fwd);
}

void EXPORT fwdmsg (id self, SEL sel, void * args, ARGIMP disp)
{
    if (sel == @selector (doesNotUnderstand:))
    { /* possible ! */
        char * msg;
        msg = "Completely messed up: Object does not understand "
              "-doesNotUnderstand:";
        report (self, msg);
    }
    else
    {
        id msg = [Message selector:sel dispatch:disp args:args];
        [self doesNotUnderstand:msg];
#ifndef OBJC_REFCNT
        msg = [msg free];
#else
        msg = iddecref (msg);
#endif
    }
}

static void selptrdisp (id self, SEL sel, id * p)
{
    p[0] = (*fwdimp (self, sel, selptrfwd)) (self, sel, p[1], p[2], p[3], p[4]);
}

id EXPORT selptrfwd (id self, SEL sel, id a, id b, id c, id d)
{
    id p[5];
    p[1] = a;
    p[2] = b;
    p[3] = c;
    p[4] = d;
    fwdmsg (self, sel, p, (ARGIMP)selptrdisp);
    return p[0];
}

/*
 * This function is for compatibility with Stepstone.
 * Used in Producer.
 */

void EXPORT dbg (char * fmt, ...)
{
    if (dbgFlag)
    {
        OC_VA_LIST arglist;
        OC_VA_START (arglist, fmt);
        vfprintf (dbgIOD, fmt, arglist);
        OC_VA_END (arglist);
        fflush (dbgIOD);
    }
}

ocMethod getInstanceMethod (id cls, SEL sel)
{
    Cls_t wCls;
    id ncls = cls; /* working class */

    do
    {
        long n;
        ocMethod methDesc;

        wCls     = getcls (ncls);
        methDesc = wCls->clsDispTable;

        for (n = 0; n < wCls->clsSizDict; n++, methDesc++)
        {
            if (sel == methDesc->_cmd)
            {
                return methDesc;
            }
        }
    } while ((ncls = wCls->clsSuper));

    return 0;
}

/*****************************************************************************
 *
 * Adding Methods (as for Categories)
 *
 ****************************************************************************/

static struct objcrt_slt * newDispTable (int n)
{
    return (struct objcrt_slt *)OC_Malloc (n * sizeof (struct objcrt_slt));
}

static void copyDispTable (struct objcrt_slt * dst, struct objcrt_slt * src,
                           int n)
{
    while (n--)
    {
        dst->_imp = src->_imp;
        dst->_typ = src->_typ;
        dst->_cmd = src->_cmd;
        dst++;
        src++;
    }
}

static void freeDispTable (struct objcrt_slt * self)
{
    /* in any case, don't free the statically (compiler) allocated ones */
}

static void addnstmeths (Cls_t src, Cls_t dst)
{
    struct objcrt_slt * n = newDispTable (dst->clsSizDict + src->clsSizDict);
    copyDispTable (n, dst->clsDispTable, dst->clsSizDict);
    copyDispTable (n + dst->clsSizDict, src->clsDispTable, src->clsSizDict);
    dst->clsSizDict += src->clsSizDict;
    freeDispTable (dst->clsDispTable);
    dst->clsDispTable = n;
}

void addMethods (id isrc, id idst)
{
    STR srcName, dstName;
    Cls_t src = getcls (isrc);
    Cls_t dst = getcls (idst);

    /* can happen from inside +initialize */
    if (src == dst)
        return;

    /* check direct subclass; otherwise, if A has subclass B, and B
     * has subclass C, and [C poseAs:A] then B will inherit from both
     * C and A
     */

    srcName = src->clsName;
    dstName = dst->clsName;

    if (src->clsSuper && getcls (src->clsSuper) != dst)
    {
        [isrc error:"addMethods: %s not direct subclass of %s.", srcName,
                    dstName];
    }

    if (src->clsSizInstance != dst->clsSizInstance)
    {
        [isrc error:"addMethods: %s adds instance variables to %s.", srcName,
                    dstName];
    }

    addnstmeths (src, dst);
    addnstmeths (getmeta (src), getmeta (dst));

    /* flush message caches */
    flushCache ();
}

int replaceMethod (id destn, SEL sel, IMP imp, TYP typ)
{
    Cls_t cls = getcls (destn);
    long n;
    struct objcrt_slt * smt = cls->clsDispTable;

    for (n = 0; n < cls->clsSizDict; n++, smt++)
    {
        /* selectors can be compared with '==' */
        if (smt->_cmd == sel)
        {
            smt->_imp = imp;
            smt->_typ = typ;
            return 0;
        }
    }
    return 1;
}

void exchangeImplementations (ocMethod one, ocMethod two)
{
    IMP tmp   = two->_imp;
    two->_imp = one->_imp;
    one->_imp = tmp;
}

/*****************************************************************************
 *
 * Class Posing
 *
 ****************************************************************************/

id swapclass (id self, id other)
{
#if OTBCRT
    struct OTB * fake      = (struct OTB *)self;
    struct _PRIVATE * temp = fake->ptr;
    fake->ptr              = other->ptr;
    other->ptr = temp;
    flushCache (); /* important for classes */
#endif
    return self;
}

void poseAs (id iposing, id itarget)
{
    modnode_t m;
    Mentry_t modPtr;
    STR newName, posingName, targetName;
    Cls_t posing = getcls (iposing);
    Cls_t target = getcls (itarget);

    /* can happen from inside +initialize */
    if (posing == target)
        return;

    /* check direct subclass; otherwise, if A has subclass B, and B
     * has subclass C, and [C poseAs:A] then B will inherit from both
     * C and A
     */

    posingName = posing->clsName;
    targetName = target->clsName;

    if (!hasposing (target))
    {
        [itarget error:"poseAs: %s needs to be recompiled", targetName];
    }

    if (posing->clsSuper && getcls (posing->clsSuper) != target)
    {
        [iposing error:"poseAs: %s not direct subclass of %s.", posingName,
                       targetName];
    }

    if (posing->clsSizInstance != target->clsSizInstance)
    {
        [iposing error:"poseAs: %s adds instance variables to %s.", posingName,
                       targetName];
    }

    /* first change names.  this means that findClass: will return
     * the posing class in the future; the old class can still be
     * obtained as "_%<classname>".
     */

    newName = (char *)OC_Malloc (strlen (targetName) + 2 + 1);
    strcpy (newName, "_%");
    strcpy (newName + 2, targetName);

    posing->clsName = targetName;
    getmeta (posing)->clsName = getmeta (target)->clsName;
    target->clsName = newName + 1;
    getmeta (target)->clsName = newName;

    /* now "patch" the hierarchy.  look for subclasses of 'target'
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

    /* finally, assign the class external */
    assert (hasposing (target));
    if (target->clsGlbl)
        *(target->clsGlbl) = iposing;

    /* flush message caches */
    flushCache ();
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

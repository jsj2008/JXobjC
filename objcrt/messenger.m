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

#include "objcrt.h"
#include "access.h"
#include "mod.h"

#include "Object.h"
#include "Message.h"

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

void flushCache (void)
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

    if (_objcinitflag ())
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
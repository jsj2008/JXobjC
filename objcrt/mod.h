/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef MOD_H_
#define MOD_H_

#include "objc-defs.h"

/* Masks for modStatus
 * MOD_MORETHANONE is a stes extension : compiler flags when more
 * than one class per module; in this case modClsLst is '0' terminated.
 */
#define MOD_EARLYBIND 0x1L /* unused, old Stepstone */
#define MOD_MAPPED 0x2L    /* marked after selectors mapped */
#define MOD_MORETHANONE 0x4L

/*
 * Module Types.
 * These types should be compatible with what the compiler generates.
 */
typedef struct objcrt_modDescriptor MOD, *PMOD;
typedef struct objcrt_methodDescriptor METH, *PMETH; /* for static binding */

struct objcrt_modDescriptor
{
    STR modName;
    STR modVersion;
    long modStatus;
    SEL modMinSel;
    SEL modMaxSel;
    id * modClsLst; /* single or array of class globals */
    short modSelRef;
    SEL * modSelTbl;
    PMETH modMapTbl; /* not used */
};

struct objcrt_modEntry
{
    PMOD (*modLink) ();
    PMOD modInfo;
};

typedef struct objcrt_modEntry * Mentry_t;

/* Use Descriptor for automatic initialization (as opposed to postLink).
 * Should match struct useDescriptor emitted by compiler.
 */

struct objcrt_useDescriptor
{
    int processed;
    struct objcrt_useDescriptor * next;
    struct objcrt_useDescriptor *** uses;
    struct objcrt_modDescriptor * (*bind) ();
};

BOOL _objcinitflag ();
void initcls (id cls);

void _mod_poseAs (id iposing, id itarget);

#endif

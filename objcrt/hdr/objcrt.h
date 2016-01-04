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

#ifndef __objcrt__
#define __objcrt__

#include <stdio.h>   /* FILE */
#include <stddef.h>  /* size_t */
#include <pthread.h> /* mutex */

#ifndef EXPORT
#define EXPORT /* empty */
#endif

#ifndef EXTERNC
#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif
#endif

/* The "id" type is assumed to be defined by the compiler
 * (in the case of objc or objcc, by emitting a typedef)
 * This also allows for cross compiles with gcc in ObjC mode
 * because a definition here would redefine its builtin "id".
 */

/* The traditional Objective C types (see Brad Cox' book)
 */

typedef char * SEL;          /* Uniqued String for Selector */
typedef char * TYP;          /* Type description for a method */
typedef char * STR;          /* C, NULL-terminated, String */
typedef char BOOL;           /* Boolean */
typedef FILE * IOD;          /* I/O Device */
typedef id SHR;              /* type of class, for us, it's id */
typedef double TimeInterval; /* time interval in seconds */

#ifdef __cplusplus
typedef id (*IMP) (...); /* Method pointer */
#else
typedef id (*IMP) (); /* Method pointer */
#endif

typedef void (*ARGIMP) (id, SEL, void *); /* dispatcher */

#if defined(WINDOWS) || defined(__WIN32) || defined(__WIN64)
#define OBJC_WINDOWS 1
typedef SOCKET SocketDescriptor;
#else
typedef int SocketDescriptor;
#endif

/* The traditional Objective C defines
 */

#ifndef YES
#define YES (BOOL)1 /* Boolean TRUE */
#endif

#ifndef NO
#define NO (BOOL)0 /* Boolean FALSE */
#endif

#ifndef nil
#define nil (id)0 /* id of Nil instance */
#endif

typedef struct _Range
{
    size_t location, length;
} Range;

static inline Range MakeRange (size_t location, size_t length)
{
    Range range = {location, length};
    return range;
}

/* varargs for _error error reporting
 */

#include <stdarg.h>
#define OC_VA_LIST va_list
#define OC_VA_START(ap, larg) va_start (ap, larg)
#define OC_VA_ARG(ap, type) va_arg (ap, type)
#define OC_VA_END(ap) va_end (ap)

/* Types for Objective C classes.

 * These SHOULD MATCH what the compiler is emitting (for struct _PRIVATE
 * and struct _SHARED).
 *
 * All of this is sort of ugly, and error prone (since the types need to
 * be kept in sync), but needed for cross-compiles (different runtimes
 * & compilers)...
 */

struct objcrt_private
{
    id isa;
    unsigned int _refcnt;
    void * _lock;
};

struct objcrt_shared
{
    id isa;
    unsigned int _refcnt;
    void * _lock;
    id clsSuper;
    char * clsName;
    char * clsTypes;
    long clsSizInstance;
    long clsSizDict;
    struct objcrt_slt * clsDispTable;
    long clsStatus;
    struct objcrt_modDescriptor * clsMod;
    unsigned clsVersion;
    id clsCats;   /* obsolete, will go away */
    id * clsGlbl; /* only if CLS_POSING */
};

typedef struct objcrt_shared * Cls_t; /* use only for impl */

/* Masks for clsStatus */

#define CLS_FACTORY 0x1L
#define CLS_META 0x2L
#define CLS_INITIALIZED 0x4L
#define CLS_POSING 0x8L /* unused, but present in, Stepstn. */
#define CLS_MAPPED 0x10L
#define CLS_CATS 0x20L   /* obsoleted, will go away */
#define CLS_CAT 0x40L    /* new category implementation 10/97 */
#define CLS_REFCNT 0x80L /* refcnt classes 1/99 */

/* CLS_POSING isn't actually used it seems for Stepstone
 * (although they define it).  Let's use this flag to check whether
 * the class has a clsGlbl field (which our implementation uses)
 */

#define hasposing(aCls) ((aCls)->clsStatus & CLS_POSING)

#ifndef OTBCRT
#define getcls(x) ((Cls_t) (x))
#else
#define getcls(x) ((Cls_t) ((x)->ptr))
#endif

/* Dispatch table entry.
 * Used in struct _SHARED as _SLT...
 * Must match what the compiler (objc or objcc) is emitting
 */

typedef struct objcrt_slt
{
    SEL _cmd;
    TYP _typ;
    IMP _imp;
} * ocMethod;

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

/*
 * HashTable Types
 */

typedef struct hashedSelector
{
    struct hashedSelector * next;
    STR key;
} HASH, *PHASH;

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

struct objcrt_methodDescriptor
{/* for static binding - not used */
    id * cls;
    SEL * sel;
    IMP imp;
};

/* Masks for modStatus
 * MOD_MORETHANONE is a stes extension : compiler flags when more
 * than one class per module; in this case modClsLst is '0' terminated.
 */

#define MOD_EARLYBIND 0x1L /* unused, old Stepstone */
#define MOD_MAPPED 0x2L    /* marked after selectors mapped */
#define MOD_MORETHANONE 0x4L

/* C Messenger interface - try to be compatible */

/* msg tracing */
extern BOOL msgFlag;     /* message tracing */
extern FILE * msgIOD;    /* device for message tracing */
extern FILE * dbgIOD;    /* device for dbg() call */
extern BOOL allocFlag;   /* allocation tracing */
extern BOOL dbgFlag;     /* verbose dbg() calls */
extern BOOL noCacheFlag; /* disable messenger caching */
extern BOOL noNilRcvr;   /* do not allow msg. to nil */

SEL EXPORT selUid (STR);
STR EXPORT selName (SEL);
void EXPORT dbg (char * fmt, ...);
void EXPORT prnstack (FILE * file);
void EXPORT loadobjc (void * modPtr);
void EXPORT unloadobjc (void * modPtr);

/* We can not emit this in a public header for C++
 * (which is picky about the conflict between the prototype the compiler
 * emits vs. the one in the header)
 */

EXTERNC IMP EXPORT _imp (id, SEL);
EXTERNC IMP EXPORT _impSuper (id, SEL);

/* our own (new) forwarding C messenger */
EXTERNC IMP EXPORT fwdimp (id, SEL, IMP);
EXTERNC IMP EXPORT fwdimpSuper (id, SEL, IMP);
EXTERNC void EXPORT fwdmsg (id, SEL, void *, ARGIMP);
EXTERNC id EXPORT selptrfwd (id, SEL, id, id, id, id);

/* refcount functions */
EXTERNC id EXPORT idincref (id obj);
EXTERNC id EXPORT idassign (id * lhs, id rhs);
EXTERNC id EXPORT iddecref (id obj);

/* Vectors.
 * Can't make those vectors public unless we
 * make OBJCRT_USE_PREFIXED_NAMES public
 * the "extern" def for vectors is important for SGI cc
 */

extern id (*JX_alloc) (id, unsigned int);    /*allocate a new object */
extern id (*JX_dealloc) (id);                /* deallocate an object */
extern id (*JX_copy) (id, unsigned int);     /* shallow copy an object */
extern id (*JX_error) (id, STR, OC_VA_LIST); /* error handler */

extern id (*JX_cvtToId) (STR);   /* convert string name to class id */
extern SEL (*JX_cvtToSel) (STR); /* convert string to selector */

extern id (*JX_fileIn) (FILE *);
extern BOOL (*JX_fileOut) (FILE *, id);
extern BOOL (*JX_storeOn) (STR, id);
extern id (*JX_readFrom) (STR);
void EXPORT setfilein (id (*f) (FILE *));
void EXPORT setfileout (BOOL (*f) (FILE *, id));

extern id (*JX_showOn) (id, unsigned);

extern pthread_spinlock_t rcLock;
pthread_mutex_t EXPORT * allocMtx ();

void EXPORT * OC_Malloc (size_t);
void EXPORT * OC_MallocAtomic (size_t);
void EXPORT * OC_Calloc (size_t);
void EXPORT * OC_Realloc (void *, size_t);
void EXPORT * OC_Free (void * data);

void addSubclassesTo (id c, STR name);

id newsubclass (STR name, id superClass, int ivars, int cvars);
void linkclass (id aclass);
void unlinkclass (id aclass);

void addMethods (id src, id dst);
ocMethod getInstanceMethod (id cls, SEL sel);
int replaceMethod (id destn, SEL sel, IMP imp, TYP typ);
void exchangeImplementations (ocMethod one, ocMethod two);

void poseAs (id posing, id target);
id swapclass (id self, id target);

#endif /* __objcrt__ */
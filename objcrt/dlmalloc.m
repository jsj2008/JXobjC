/*
  This is a version (aka dlmalloc) of malloc/free/realloc written by
  Doug Lea and released to the public domain, as explained at
  http://creativecommons.org/publicdomain/zero/1.0/ Send questions,
  comments, complaints, performance data, etc to dl@cs.oswego.edu
*/

#include "dlmalloc.h"

/*------------------------------ internal #includes ---------------------- */

#ifdef _MSC_VER
#pragma warning(disable : 4146) /* no "unsigned" warnings */
#endif                          /* _MSC_VER */
#if !NO_MALLOC_STATS
#include <stdio.h> /* for printing in malloc_stats */
#endif             /* NO_MALLOC_STATS */
#ifndef LACKS_ERRNO_H
#include <errno.h> /* for MALLOC_FAILURE_ACTION */
#endif             /* LACKS_ERRNO_H */
#if ABORT_ON_ASSERT_FAILURE
#undef assert
#define assert(x)                                                              \
    if (!(x))                                                                  \
    ABORT
#else /* ABORT_ON_ASSERT_FAILURE */
#include <assert.h>
#endif /* ABORT_ON_ASSERT_FAILURE */
#if !defined(WIN32) && !defined(LACKS_TIME_H)
#include <time.h> /* for magic initialization */
#endif            /* WIN32 */
#ifndef LACKS_STDLIB_H
#include <stdlib.h> /* for abort() */
#endif              /* LACKS_STDLIB_H */
#ifndef LACKS_STRING_H
#include <string.h> /* for memset etc */
#endif              /* LACKS_STRING_H */
#if USE_BUILTIN_FFS
#ifndef LACKS_STRINGS_H
#include <strings.h> /* for ffs */
#endif               /* LACKS_STRINGS_H */
#endif               /* USE_BUILTIN_FFS */
#if HAVE_MMAP
#ifndef LACKS_SYS_MMAN_H
/* On some versions of linux, mremap decl in mman.h needs __USE_GNU set */
#if (defined(linux) && !defined(__USE_GNU))
#define __USE_GNU 1
#include <sys/mman.h> /* for mmap */
#undef __USE_GNU
#else
#include <sys/mman.h> /* for mmap */
#endif                /* linux */
#endif                /* LACKS_SYS_MMAN_H */
#ifndef LACKS_FCNTL_H
#include <fcntl.h>
#endif /* LACKS_FCNTL_H */
#endif /* HAVE_MMAP */
#ifndef LACKS_UNISTD_H
#include <unistd.h> /* for sbrk, sysconf */
#else               /* LACKS_UNISTD_H */
#if !defined(__FreeBSD__) && !defined(__OpenBSD__) && !defined(__NetBSD__)
extern void * sbrk (ptrdiff_t);
#endif /* FreeBSD etc */
#endif /* LACKS_UNISTD_H */

/* Declarations for locking */
#ifndef WIN32
#if defined(__SVR4) && defined(__sun) /* solaris */
#include <thread.h>
#elif !defined(LACKS_SCHED_H)
#include <sched.h>
#endif /* solaris or LACKS_SCHED_H */
#if (defined(USE_RECURSIVE_LOCKS) && USE_RECURSIVE_LOCKS != 0) ||              \
    !USE_SPIN_LOCKS
#include <pthread.h>
#endif /* USE_RECURSIVE_LOCKS ... */
#elif defined(_MSC_VER)
#ifndef _M_AMD64
/* These are already defined on AMD64 builds */
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */
LONG __cdecl _InterlockedCompareExchange (LONG volatile * Dest, LONG Exchange,
                                          LONG Comp);
LONG __cdecl _InterlockedExchange (LONG volatile * Target, LONG Value);
#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* _M_AMD64 */
#pragma intrinsic(_InterlockedCompareExchange)
#pragma intrinsic(_InterlockedExchange)
#define interlockedcompareexchange _InterlockedCompareExchange
#define interlockedexchange _InterlockedExchange
#elif defined(WIN32) && defined(__GNUC__)
#define interlockedcompareexchange(a, b, c)                                    \
    __sync_val_compare_and_swap (a, c, b)
#define interlockedexchange __sync_lock_test_and_set
#endif /* Win32 */

#ifndef LOCK_AT_FORK
#define LOCK_AT_FORK 0
#endif

/* Declarations for bit scanning on win32 */
#if defined(_MSC_VER) && _MSC_VER >= 1300
#ifndef BitScanForward /* Try to avoid pulling in WinNT.h */
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */
unsigned char _BitScanForward (unsigned long * index, unsigned long mask);
unsigned char _BitScanReverse (unsigned long * index, unsigned long mask);
#ifdef __cplusplus
}
#endif /* __cplusplus */

#define BitScanForward _BitScanForward
#define BitScanReverse _BitScanReverse
#pragma intrinsic(_BitScanForward)
#pragma intrinsic(_BitScanReverse)
#endif /* BitScanForward */
#endif /* defined(_MSC_VER) && _MSC_VER>=1300 */

#ifndef WIN32
#ifndef malloc_getpagesize
#ifdef _SC_PAGESIZE /* some SVR4 systems omit an underscore */
#ifndef _SC_PAGE_SIZE
#define _SC_PAGE_SIZE _SC_PAGESIZE
#endif
#endif
#ifdef _SC_PAGE_SIZE
#define malloc_getpagesize sysconf (_SC_PAGE_SIZE)
#else
#if defined(BSD) || defined(DGUX) || defined(HAVE_GETPAGESIZE)
extern size_t getpagesize ();
#define malloc_getpagesize getpagesize ()
#else
#ifdef WIN32 /* use supplied emulation of getpagesize */
#define malloc_getpagesize getpagesize ()
#else
#ifndef LACKS_SYS_PARAM_H
#include <sys/param.h>
#endif
#ifdef EXEC_PAGESIZE
#define malloc_getpagesize EXEC_PAGESIZE
#else
#ifdef NBPG
#ifndef CLSIZE
#define malloc_getpagesize NBPG
#else
#define malloc_getpagesize (NBPG * CLSIZE)
#endif
#else
#ifdef NBPC
#define malloc_getpagesize NBPC
#else
#ifdef PAGESIZE
#define malloc_getpagesize PAGESIZE
#else /* just guess */
#define malloc_getpagesize ((size_t)4096U)
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* ------------------- size_t and alignment properties -------------------- */

/* The byte and bit size of a size_t */
#define SIZE_T_SIZE (sizeof (size_t))
#define SIZE_T_BITSIZE (sizeof (size_t) << 3)

/* Some constants coerced to size_t */
/* Annoying but necessary to avoid errors on some platforms */
#define SIZE_T_ZERO ((size_t)0)
#define SIZE_T_ONE ((size_t)1)
#define SIZE_T_TWO ((size_t)2)
#define SIZE_T_FOUR ((size_t)4)
#define TWO_SIZE_T_SIZES (SIZE_T_SIZE << 1)
#define FOUR_SIZE_T_SIZES (SIZE_T_SIZE << 2)
#define SIX_SIZE_T_SIZES (FOUR_SIZE_T_SIZES + TWO_SIZE_T_SIZES)
#define HALF_MAX_SIZE_T (MAX_SIZE_T / 2U)

/* The bit mask value corresponding to MALLOC_ALIGNMENT */
#define CHUNK_ALIGN_MASK (MALLOC_ALIGNMENT - SIZE_T_ONE)

/* True if address a has acceptable alignment */
#define is_aligned(A) (((size_t) ((A)) & (CHUNK_ALIGN_MASK)) == 0)

/* the number of bytes to offset an address to align it */
#define align_offset(A)                                                        \
    ((((size_t) (A)&CHUNK_ALIGN_MASK) == 0)                                    \
         ? 0                                                                   \
         : ((MALLOC_ALIGNMENT - ((size_t) (A)&CHUNK_ALIGN_MASK)) &             \
            CHUNK_ALIGN_MASK))

/* -------------------------- MMAP preliminaries ------------------------- */

/*
   If HAVE_MORECORE or HAVE_MMAP are false, we just define calls and
   checks to fail so compiler optimizer can delete code rather than
   using so many "#if"s.
*/

/* MORECORE and MMAP must return MFAIL on failure */
#define MFAIL ((void *)(MAX_SIZE_T))
#define CMFAIL ((char *)(MFAIL)) /* defined for convenience */

#if HAVE_MMAP

#ifndef WIN32
#define MUNMAP_DEFAULT(a, s) munmap ((a), (s))
#define MMAP_PROT (PROT_READ | PROT_WRITE)
#if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#define MAP_ANONYMOUS MAP_ANON
#endif /* MAP_ANON */
#ifdef MAP_ANONYMOUS
#define MMAP_FLAGS (MAP_PRIVATE | MAP_ANONYMOUS)
#define MMAP_DEFAULT(s) mmap (0, (s), MMAP_PROT, MMAP_FLAGS, -1, 0)
#else /* MAP_ANONYMOUS */
/*
   Nearly all versions of mmap support MAP_ANONYMOUS, so the following
   is unlikely to be needed, but is supplied just in case.
*/
#define MMAP_FLAGS (MAP_PRIVATE)
static int dev_zero_fd = -1; /* Cached file descriptor for /dev/zero. */
#define MMAP_DEFAULT(s)                                                        \
    ((dev_zero_fd < 0)                                                         \
         ? (dev_zero_fd = open ("/dev/zero", O_RDWR),                          \
            mmap (0, (s), MMAP_PROT, MMAP_FLAGS, dev_zero_fd, 0))              \
         : mmap (0, (s), MMAP_PROT, MMAP_FLAGS, dev_zero_fd, 0))
#endif /* MAP_ANONYMOUS */

#define DIRECT_MMAP_DEFAULT(s) MMAP_DEFAULT (s)

#else /* WIN32 */

/* Win32 MMAP via VirtualAlloc */
static FORCEINLINE void * win32mmap (size_t size)
{
    void * ptr =
        VirtualAlloc (0, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    return (ptr != 0) ? ptr : MFAIL;
}

/* For direct MMAP, use MEM_TOP_DOWN to minimize interference */
static FORCEINLINE void * win32direct_mmap (size_t size)
{
    void * ptr = VirtualAlloc (0, size, MEM_RESERVE | MEM_COMMIT | MEM_TOP_DOWN,
                               PAGE_READWRITE);
    return (ptr != 0) ? ptr : MFAIL;
}

/* This function supports releasing coalesed segments */
static FORCEINLINE int win32munmap (void * ptr, size_t size)
{
    MEMORY_BASIC_INFORMATION minfo;
    char * cptr = (char *)ptr;
    while (size)
    {
        if (VirtualQuery (cptr, &minfo, sizeof (minfo)) == 0)
            return -1;
        if (minfo.BaseAddress != cptr || minfo.AllocationBase != cptr ||
            minfo.State != MEM_COMMIT || minfo.RegionSize > size)
            return -1;
        if (VirtualFree (cptr, 0, MEM_RELEASE) == 0)
            return -1;
        cptr += minfo.RegionSize;
        size -= minfo.RegionSize;
    }
    return 0;
}

#define MMAP_DEFAULT(s) win32mmap (s)
#define MUNMAP_DEFAULT(a, s) win32munmap ((a), (s))
#define DIRECT_MMAP_DEFAULT(s) win32direct_mmap (s)
#endif /* WIN32 */
#endif /* HAVE_MMAP */

/**
 * Define CALL_MORECORE
 */
#if HAVE_MORECORE
#ifdef MORECORE
#define CALL_MORECORE(S) MORECORE (S)
#else /* MORECORE */
#define CALL_MORECORE(S) MORECORE_DEFAULT (S)
#endif /* MORECORE */
#else  /* HAVE_MORECORE */
#define CALL_MORECORE(S) MFAIL
#endif /* HAVE_MORECORE */

/**
 * Define CALL_MMAP/CALL_MUNMAP/CALL_DIRECT_MMAP
 */
#if HAVE_MMAP
#define USE_MMAP_BIT (SIZE_T_ONE)

#ifdef MMAP
#define CALL_MMAP(s) MMAP (s)
#else /* MMAP */
#define CALL_MMAP(s) MMAP_DEFAULT (s)
#endif /* MMAP */
#ifdef MUNMAP
#define CALL_MUNMAP(a, s) MUNMAP ((a), (s))
#else /* MUNMAP */
#define CALL_MUNMAP(a, s) MUNMAP_DEFAULT ((a), (s))
#endif /* MUNMAP */
#ifdef DIRECT_MMAP
#define CALL_DIRECT_MMAP(s) DIRECT_MMAP (s)
#else /* DIRECT_MMAP */
#define CALL_DIRECT_MMAP(s) DIRECT_MMAP_DEFAULT (s)
#endif /* DIRECT_MMAP */
#else  /* HAVE_MMAP */
#define USE_MMAP_BIT (SIZE_T_ZERO)

#define MMAP(s) MFAIL
#define MUNMAP(a, s) (-1)
#define DIRECT_MMAP(s) MFAIL
#define CALL_DIRECT_MMAP(s) DIRECT_MMAP (s)
#define CALL_MMAP(s) MMAP (s)
#define CALL_MUNMAP(a, s) MUNMAP ((a), (s))
#endif /* HAVE_MMAP */

/**
 * Define CALL_MREMAP
 */
#define CALL_MREMAP(addr, osz, nsz, mv) MFAIL

/* mstate bit set if continguous morecore disabled or failed */
#define USE_NONCONTIGUOUS_BIT (4U)

/* segment bit set in create_mspace_with_base */
#define EXTERN_BIT (8U)

/* --------------------------- Lock preliminaries ------------------------ */

#if USE_SPIN_LOCKS

/* First, define CAS_LOCK and CLEAR_LOCK on ints */
/* Note CAS_LOCK defined to return 0 on success */

#if defined(__GNUC__) &&                                                       \
    (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
#define CAS_LOCK(sl) __sync_lock_test_and_set (sl, 1)
#define CLEAR_LOCK(sl) __sync_lock_release (sl)

#elif(defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__)))
/* Custom spin locks for older gcc on x86 */
static FORCEINLINE int x86_cas_lock (int * sl)
{
    int ret;
    int val = 1;
    int cmp = 0;
    __asm__ __volatile__("lock; cmpxchgl %1, %2"
                         : "=a"(ret)
                         : "r"(val), "m"(*(sl)), "0"(cmp)
                         : "memory", "cc");
    return ret;
}

static FORCEINLINE void x86_clear_lock (int * sl)
{
    assert (*sl != 0);
    int prev = 0;
    int ret;
    __asm__ __volatile__("lock; xchgl %0, %1"
                         : "=r"(ret)
                         : "m"(*(sl)), "0"(prev)
                         : "memory");
}

#define CAS_LOCK(sl) x86_cas_lock (sl)
#define CLEAR_LOCK(sl) x86_clear_lock (sl)

#else /* Win32 MSC */
#define CAS_LOCK(sl) interlockedexchange (sl, (LONG)1)
#define CLEAR_LOCK(sl) interlockedexchange (sl, (LONG)0)

#endif /* ... gcc spins locks ... */

/* How to yield for a spin lock */
#define SPINS_PER_YIELD 63
#if defined(_MSC_VER)
#define SLEEP_EX_DURATION 50 /* delay for yield/sleep */
#define SPIN_LOCK_YIELD SleepEx (SLEEP_EX_DURATION, FALSE)
#elif defined(__SVR4) && defined(__sun) /* solaris */
#define SPIN_LOCK_YIELD thr_yield ();
#elif !defined(LACKS_SCHED_H)
#define SPIN_LOCK_YIELD sched_yield ();
#else
#define SPIN_LOCK_YIELD
#endif /* ... yield ... */

#if !defined(USE_RECURSIVE_LOCKS) || USE_RECURSIVE_LOCKS == 0
/* Plain spin locks use single word (embedded in malloc_states) */
static int spin_acquire_lock (int * sl)
{
    int spins = 0;
    while (*(volatile int *)sl != 0 || CAS_LOCK (sl))
    {
        if ((++spins & SPINS_PER_YIELD) == 0)
        {
            SPIN_LOCK_YIELD;
        }
    }
    return 0;
}

#define MLOCK_T int
#define TRY_LOCK(sl) !CAS_LOCK (sl)
#define RELEASE_LOCK(sl) CLEAR_LOCK (sl)
#define ACQUIRE_LOCK(sl) (CAS_LOCK (sl) ? spin_acquire_lock (sl) : 0)
#define INITIAL_LOCK(sl) (*sl = 0)
#define DESTROY_LOCK(sl) (0)
static MLOCK_T malloc_global_mutex = 0;

#else /* USE_RECURSIVE_LOCKS */
/* types for lock owners */
#ifdef WIN32
#define THREAD_ID_T DWORD
#define CURRENT_THREAD GetCurrentThreadId ()
#define EQ_OWNER(X, Y) ((X) == (Y))
#else
/*
  Note: the following assume that pthread_t is a type that can be
  initialized to (casted) zero. If this is not the case, you will need to
  somehow redefine these or not use spin locks.
*/
#define THREAD_ID_T pthread_t
#define CURRENT_THREAD pthread_self ()
#define EQ_OWNER(X, Y) pthread_equal (X, Y)
#endif

struct malloc_recursive_lock
{
    int sl;
    unsigned int c;
    THREAD_ID_T threadid;
};

#define MLOCK_T struct malloc_recursive_lock
static MLOCK_T malloc_global_mutex = {0, 0, (THREAD_ID_T)0};

static FORCEINLINE void recursive_release_lock (MLOCK_T * lk)
{
    assert (lk->sl != 0);
    if (--lk->c == 0)
    {
        CLEAR_LOCK (&lk->sl);
    }
}

static FORCEINLINE int recursive_acquire_lock (MLOCK_T * lk)
{
    THREAD_ID_T mythreadid = CURRENT_THREAD;
    int spins = 0;
    for (;;)
    {
        if (*((volatile int *)(&lk->sl)) == 0)
        {
            if (!CAS_LOCK (&lk->sl))
            {
                lk->threadid = mythreadid;
                lk->c        = 1;
                return 0;
            }
        }
        else if (EQ_OWNER (lk->threadid, mythreadid))
        {
            ++lk->c;
            return 0;
        }
        if ((++spins & SPINS_PER_YIELD) == 0)
        {
            SPIN_LOCK_YIELD;
        }
    }
}

static FORCEINLINE int recursive_try_lock (MLOCK_T * lk)
{
    THREAD_ID_T mythreadid = CURRENT_THREAD;
    if (*((volatile int *)(&lk->sl)) == 0)
    {
        if (!CAS_LOCK (&lk->sl))
        {
            lk->threadid = mythreadid;
            lk->c        = 1;
            return 1;
        }
    }
    else if (EQ_OWNER (lk->threadid, mythreadid))
    {
        ++lk->c;
        return 1;
    }
    return 0;
}

#define RELEASE_LOCK(lk) recursive_release_lock (lk)
#define TRY_LOCK(lk) recursive_try_lock (lk)
#define ACQUIRE_LOCK(lk) recursive_acquire_lock (lk)
#define INITIAL_LOCK(lk)                                                       \
    ((lk)->threadid = (THREAD_ID_T)0, (lk)->sl = 0, (lk)->c = 0)
#define DESTROY_LOCK(lk) (0)
#endif /* USE_RECURSIVE_LOCKS */

#elif defined(WIN32) /* Win32 critical sections */
#define MLOCK_T CRITICAL_SECTION
#define ACQUIRE_LOCK(lk) (EnterCriticalSection (lk), 0)
#define RELEASE_LOCK(lk) LeaveCriticalSection (lk)
#define TRY_LOCK(lk) TryEnterCriticalSection (lk)
#define INITIAL_LOCK(lk)                                                       \
    (!InitializeCriticalSectionAndSpinCount ((lk), 0x80000000 | 4000))
#define DESTROY_LOCK(lk) (DeleteCriticalSection (lk), 0)
#define NEED_GLOBAL_LOCK_INIT

static MLOCK_T malloc_global_mutex;
static volatile LONG malloc_global_mutex_status;

/* Use spin loop to initialize global lock */
static void init_malloc_global_mutex ()
{
    for (;;)
    {
        long stat = malloc_global_mutex_status;
        if (stat > 0)
            return;
        /* transition to < 0 while initializing, then to > 0) */
        if (stat == 0 &&
            interlockedcompareexchange (&malloc_global_mutex_status, (LONG)-1,
                                        (LONG)0) == 0)
        {
            InitializeCriticalSection (&malloc_global_mutex);
            interlockedexchange (&malloc_global_mutex_status, (LONG)1);
            return;
        }
        SleepEx (0, FALSE);
    }
}

#else /* pthreads-based locks */
#define MLOCK_T pthread_mutex_t
#define ACQUIRE_LOCK(lk) pthread_mutex_lock (lk)
#define RELEASE_LOCK(lk) pthread_mutex_unlock (lk)
#define TRY_LOCK(lk) (!pthread_mutex_trylock (lk))
#define INITIAL_LOCK(lk) pthread_init_lock (lk)
#define DESTROY_LOCK(lk) pthread_mutex_destroy (lk)

#if defined(USE_RECURSIVE_LOCKS) && USE_RECURSIVE_LOCKS != 0 &&                \
    defined(linux) && !defined(PTHREAD_MUTEX_RECURSIVE)
/* Cope with old-style linux recursive lock initialization by adding */
/* skipped internal declaration from pthread.h */
extern int pthread_mutexattr_setkind_np __P ((pthread_mutexattr_t * __attr,
                                              int __kind));
#define PTHREAD_MUTEX_RECURSIVE PTHREAD_MUTEX_RECURSIVE_NP
#define pthread_mutexattr_settype(x, y) pthread_mutexattr_setkind_np (x, y)
#endif /* USE_RECURSIVE_LOCKS ... */

static MLOCK_T malloc_global_mutex = PTHREAD_MUTEX_INITIALIZER;

static int pthread_init_lock (MLOCK_T * lk)
{
    pthread_mutexattr_t attr;
    if (pthread_mutexattr_init (&attr))
        return 1;
#if defined(USE_RECURSIVE_LOCKS) && USE_RECURSIVE_LOCKS != 0
    if (pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE))
        return 1;
#endif
    if (pthread_mutex_init (lk, &attr))
        return 1;
    if (pthread_mutexattr_destroy (&attr))
        return 1;
    return 0;
}

#endif /* ... lock types ... */

/* Common code for all lock types */
#define USE_LOCK_BIT (2U)

#ifndef ACQUIRE_MALLOC_GLOBAL_LOCK
#define ACQUIRE_MALLOC_GLOBAL_LOCK() ACQUIRE_LOCK (&malloc_global_mutex);
#endif

#ifndef RELEASE_MALLOC_GLOBAL_LOCK
#define RELEASE_MALLOC_GLOBAL_LOCK() RELEASE_LOCK (&malloc_global_mutex);
#endif

/* -----------------------  Chunk representations ------------------------ */

struct malloc_chunk
{
    size_t prev_foot;         /* Size of previous chunk (if free).  */
    size_t head;              /* Size and inuse bits. */
    struct malloc_chunk * fd; /* double links -- used only if free. */
    struct malloc_chunk * bk;
};

typedef struct malloc_chunk mchunk;
typedef struct malloc_chunk * mchunkptr;
typedef struct malloc_chunk * sbinptr; /* The type of bins of chunks */
typedef unsigned int bindex_t;         /* Described below */
typedef unsigned int binmap_t;         /* Described below */
typedef unsigned int flag_t;           /* The type of various bit flag sets */

/* ------------------- Chunks sizes and alignments ----------------------- */

#define MCHUNK_SIZE (sizeof (mchunk))

#define CHUNK_OVERHEAD (SIZE_T_SIZE)

/* MMapped chunks need a second word of overhead ... */
#define MMAP_CHUNK_OVERHEAD (TWO_SIZE_T_SIZES)
/* ... and additional padding for fake next-chunk at foot */
#define MMAP_FOOT_PAD (FOUR_SIZE_T_SIZES)

/* The smallest size we can malloc is an aligned minimal chunk */
#define MIN_CHUNK_SIZE ((MCHUNK_SIZE + CHUNK_ALIGN_MASK) & ~CHUNK_ALIGN_MASK)

/* conversion from malloc headers to user pointers, and back */
#define chunk2mem(p) ((void *)((char *)(p) + TWO_SIZE_T_SIZES))
#define mem2chunk(mem) ((mchunkptr) ((char *)(mem)-TWO_SIZE_T_SIZES))
/* chunk associated with aligned address A */
#define align_as_chunk(A) (mchunkptr) ((A) + align_offset (chunk2mem (A)))

/* Bounds on request (not chunk) sizes. */
#define MAX_REQUEST ((-MIN_CHUNK_SIZE) << 2)
#define MIN_REQUEST (MIN_CHUNK_SIZE - CHUNK_OVERHEAD - SIZE_T_ONE)

/* pad request bytes into a usable size */
#define pad_request(req)                                                       \
    (((req) + CHUNK_OVERHEAD + CHUNK_ALIGN_MASK) & ~CHUNK_ALIGN_MASK)

/* pad request, checking for minimum (but not maximum) */
#define request2size(req)                                                      \
    (((req) < MIN_REQUEST) ? MIN_CHUNK_SIZE : pad_request (req))

/* ------------------ Operations on head and foot fields ----------------- */

/*
  The head field of a chunk is or'ed with PINUSE_BIT when previous
  adjacent chunk in use, and or'ed with CINUSE_BIT if this chunk is in
  use, unless mmapped, in which case both bits are cleared.

  FLAG4_BIT is not used by this malloc, but might be useful in extensions.
*/

#define PINUSE_BIT (SIZE_T_ONE)
#define CINUSE_BIT (SIZE_T_TWO)
#define FLAG4_BIT (SIZE_T_FOUR)
#define INUSE_BITS (PINUSE_BIT | CINUSE_BIT)
#define FLAG_BITS (PINUSE_BIT | CINUSE_BIT | FLAG4_BIT)

/* Head value for fenceposts */
#define FENCEPOST_HEAD (INUSE_BITS | SIZE_T_SIZE)

/* extraction of fields from head words */
#define cinuse(p) ((p)->head & CINUSE_BIT)
#define pinuse(p) ((p)->head & PINUSE_BIT)
#define flag4inuse(p) ((p)->head & FLAG4_BIT)
#define is_inuse(p) (((p)->head & INUSE_BITS) != PINUSE_BIT)
#define is_mmapped(p) (((p)->head & INUSE_BITS) == 0)

#define chunksize(p) ((p)->head & ~(FLAG_BITS))

#define clear_pinuse(p) ((p)->head &= ~PINUSE_BIT)
#define set_flag4(p) ((p)->head |= FLAG4_BIT)
#define clear_flag4(p) ((p)->head &= ~FLAG4_BIT)

/* Treat space at ptr +/- offset as a chunk */
#define chunk_plus_offset(p, s) ((mchunkptr) (((char *)(p)) + (s)))
#define chunk_minus_offset(p, s) ((mchunkptr) (((char *)(p)) - (s)))

/* Ptr to next or previous physical malloc_chunk. */
#define next_chunk(p) ((mchunkptr) (((char *)(p)) + ((p)->head & ~FLAG_BITS)))
#define prev_chunk(p) ((mchunkptr) (((char *)(p)) - ((p)->prev_foot)))

/* extract next chunk's pinuse bit */
#define next_pinuse(p) ((next_chunk (p)->head) & PINUSE_BIT)

/* Get/set size at footer */
#define get_foot(p, s) (((mchunkptr) ((char *)(p) + (s)))->prev_foot)
#define set_foot(p, s) (((mchunkptr) ((char *)(p) + (s)))->prev_foot = (s))

/* Set size, pinuse bit, and foot */
#define set_size_and_pinuse_of_free_chunk(p, s)                                \
    ((p)->head = (s | PINUSE_BIT), set_foot (p, s))

/* Set size, pinuse bit, foot, and clear next pinuse */
#define set_free_with_pinuse(p, s, n)                                          \
    (clear_pinuse (n), set_size_and_pinuse_of_free_chunk (p, s))

/* Get the internal overhead associated with chunk p */
#define overhead_for(p) (is_mmapped (p) ? MMAP_CHUNK_OVERHEAD : CHUNK_OVERHEAD)

/* Return true if malloced space is not necessarily cleared */
#if MMAP_CLEARS
#define calloc_must_clear(p) (!is_mmapped (p))
#else /* MMAP_CLEARS */
#define calloc_must_clear(p) (1)
#endif /* MMAP_CLEARS */

/* ---------------------- Overlaid data structures ----------------------- */

struct malloc_tree_chunk
{
    /* The first four fields must be compatible with malloc_chunk */
    size_t prev_foot;
    size_t head;
    struct malloc_tree_chunk * fd;
    struct malloc_tree_chunk * bk;

    struct malloc_tree_chunk * child[2];
    struct malloc_tree_chunk * parent;
    bindex_t index;
};

typedef struct malloc_tree_chunk tchunk;
typedef struct malloc_tree_chunk * tchunkptr;
typedef struct malloc_tree_chunk * tbinptr; /* The type of bins of trees */

/* A little helper macro for trees */
#define leftmost_child(t) ((t)->child[0] != 0 ? (t)->child[0] : (t)->child[1])

/* ----------------------------- Segments -------------------------------- */

struct malloc_segment
{
    char * base;                  /* base address */
    size_t size;                  /* allocated size */
    struct malloc_segment * next; /* ptr to next segment */
    flag_t sflags;                /* mmap and extern flag */
};

#define is_mmapped_segment(S) ((S)->sflags & USE_MMAP_BIT)
#define is_extern_segment(S) ((S)->sflags & EXTERN_BIT)

typedef struct malloc_segment msegment;
typedef struct malloc_segment * msegmentptr;

/* ---------------------------- malloc_state ----------------------------- */

/* Bin types, widths and sizes */
#define NSMALLBINS (32U)
#define NTREEBINS (32U)
#define SMALLBIN_SHIFT (3U)
#define SMALLBIN_WIDTH (SIZE_T_ONE << SMALLBIN_SHIFT)
#define TREEBIN_SHIFT (8U)
#define MIN_LARGE_SIZE (SIZE_T_ONE << TREEBIN_SHIFT)
#define MAX_SMALL_SIZE (MIN_LARGE_SIZE - SIZE_T_ONE)
#define MAX_SMALL_REQUEST (MAX_SMALL_SIZE - CHUNK_ALIGN_MASK - CHUNK_OVERHEAD)

struct malloc_state
{
    binmap_t smallmap;
    binmap_t treemap;
    size_t dvsize;
    size_t topsize;
    char * least_addr;
    mchunkptr dv;
    mchunkptr top;
    size_t trim_check;
    size_t release_checks;
    size_t magic;
    mchunkptr smallbins[(NSMALLBINS + 1) * 2];
    tbinptr treebins[NTREEBINS];
    size_t footprint;
    size_t max_footprint;
    size_t footprint_limit; /* zero means no limit */
    flag_t mflags;
    MLOCK_T mutex; /* locate lock among fields that rarely change */
    msegment seg;
    void * extp; /* Unused but available for extensions */
    size_t exts;
};

typedef struct malloc_state * mstate;

/* ------------- Global malloc_state and malloc_params ------------------- */

struct malloc_params
{
    size_t magic;
    size_t page_size;
    size_t granularity;
    size_t mmap_threshold;
    size_t trim_threshold;
    flag_t default_mflags;
};

static struct malloc_params mparams;

/* Ensure mparams initialized */
#define ensure_initialization() (void) (mparams.magic != 0 || init_mparams ())

#define is_initialized(M) ((M)->top != 0)

/* -------------------------- system alloc setup ------------------------- */

/* Operations on mflags */

#define use_lock(M) ((M)->mflags & USE_LOCK_BIT)
#define enable_lock(M) ((M)->mflags |= USE_LOCK_BIT)
#define disable_lock(M) ((M)->mflags &= ~USE_LOCK_BIT)

#define use_mmap(M) ((M)->mflags & USE_MMAP_BIT)
#define enable_mmap(M) ((M)->mflags |= USE_MMAP_BIT)
#if HAVE_MMAP
#define disable_mmap(M) ((M)->mflags &= ~USE_MMAP_BIT)
#else
#define disable_mmap(M)
#endif

#define use_noncontiguous(M) ((M)->mflags & USE_NONCONTIGUOUS_BIT)
#define disable_contiguous(M) ((M)->mflags |= USE_NONCONTIGUOUS_BIT)

#define set_lock(M, L)                                                         \
    ((M)->mflags =                                                             \
         (L) ? ((M)->mflags | USE_LOCK_BIT) : ((M)->mflags & ~USE_LOCK_BIT))

/* page-align a size */
#define page_align(S)                                                          \
    (((S) + (mparams.page_size - SIZE_T_ONE)) &                                \
     ~(mparams.page_size - SIZE_T_ONE))

/* granularity-align a size */
#define granularity_align(S)                                                   \
    (((S) + (mparams.granularity - SIZE_T_ONE)) &                              \
     ~(mparams.granularity - SIZE_T_ONE))

/* For mmap, use granularity alignment on windows, else page-align */
#ifdef WIN32
#define mmap_align(S) granularity_align (S)
#else
#define mmap_align(S) page_align (S)
#endif

/* For sys_alloc, enough padding to ensure can malloc request on success */
#define SYS_ALLOC_PADDING (TOP_FOOT_SIZE + MALLOC_ALIGNMENT)

#define is_page_aligned(S)                                                     \
    (((size_t) (S) & (mparams.page_size - SIZE_T_ONE)) == 0)
#define is_granularity_aligned(S)                                              \
    (((size_t) (S) & (mparams.granularity - SIZE_T_ONE)) == 0)

/*  True if segment S holds address A */
#define segment_holds(S, A)                                                    \
    ((char *)(A) >= S->base && (char *)(A) < S->base + S->size)

/* Return segment holding given address */
static msegmentptr segment_holding (mstate m, char * addr)
{
    msegmentptr sp = &m->seg;
    for (;;)
    {
        if (addr >= sp->base && addr < sp->base + sp->size)
            return sp;
        if ((sp = sp->next) == 0)
            return 0;
    }
}

/* Return true if segment contains a segment link */
static int has_segment_link (mstate m, msegmentptr ss)
{
    msegmentptr sp = &m->seg;
    for (;;)
    {
        if ((char *)sp >= ss->base && (char *)sp < ss->base + ss->size)
            return 1;
        if ((sp = sp->next) == 0)
            return 0;
    }
}

#ifndef MORECORE_CANNOT_TRIM
#define should_trim(M, s) ((s) > (M)->trim_check)
#else /* MORECORE_CANNOT_TRIM */
#define should_trim(M, s) (0)
#endif /* MORECORE_CANNOT_TRIM */

/*
  TOP_FOOT_SIZE is padding at the end of a segment, including space
  that may be needed to place segment records and fenceposts when new
  noncontiguous segments are added.
*/
#define TOP_FOOT_SIZE                                                          \
    (align_offset (chunk2mem (0)) +                                            \
     pad_request (sizeof (struct malloc_segment)) + MIN_CHUNK_SIZE)

/* -------------------------------  Hooks -------------------------------- */

/*
  PREACTION should be defined to return 0 on success, and nonzero on
  failure. If you are not using locking, you can redefine these to do
  anything you like.
*/

#define PREACTION(M) ((use_lock (M)) ? ACQUIRE_LOCK (&(M)->mutex) : 0)
#define POSTACTION(M)                                                          \
    {                                                                          \
        if (use_lock (M))                                                      \
            RELEASE_LOCK (&(M)->mutex);                                        \
    }

/*
  CORRUPTION_ERROR_ACTION is triggered upon detected bad addresses.
  USAGE_ERROR_ACTION is triggered on detected bad frees and
  reallocs. The argument p is an address that might have triggered the
  fault. It is ignored by the two predefined actions, but might be
  useful in custom actions that try to help diagnose errors.
*/

#ifndef CORRUPTION_ERROR_ACTION
#define CORRUPTION_ERROR_ACTION(m) ABORT
#endif /* CORRUPTION_ERROR_ACTION */

#ifndef USAGE_ERROR_ACTION
#define USAGE_ERROR_ACTION(m, p) ABORT
#endif /* USAGE_ERROR_ACTION */

/* -------------------------- Debugging setup ---------------------------- */

#define check_free_chunk(M, P)
#define check_inuse_chunk(M, P)
#define check_malloced_chunk(M, P, N)
#define check_mmapped_chunk(M, P)
#define check_malloc_state(M)
#define check_top_chunk(M, P)

/* ---------------------------- Indexing Bins ---------------------------- */

#define is_small(s) (((s) >> SMALLBIN_SHIFT) < NSMALLBINS)
#define small_index(s) (bindex_t) ((s) >> SMALLBIN_SHIFT)
#define small_index2size(i) ((i) << SMALLBIN_SHIFT)
#define MIN_SMALL_INDEX (small_index (MIN_CHUNK_SIZE))

/* addressing by index. See above about smallbin repositioning */
#define smallbin_at(M, i) ((sbinptr) ((char *)&((M)->smallbins[(i) << 1])))
#define treebin_at(M, i) (&((M)->treebins[i]))

/* assign tree index for size S to variable I. Use x86 asm if possible  */
#if defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__))
#define compute_tree_index(S, I)                                               \
    {                                                                          \
        unsigned int X = S >> TREEBIN_SHIFT;                                   \
        if (X == 0)                                                            \
            I = 0;                                                             \
        else if (X > 0xFFFF)                                                   \
            I = NTREEBINS - 1;                                                 \
        else                                                                   \
        {                                                                      \
            unsigned int K = (unsigned)sizeof (X) * __CHAR_BIT__ - 1 -         \
                             (unsigned)__builtin_clz (X);                      \
            I = (bindex_t) ((K << 1) +                                         \
                            ((S >> (K + (TREEBIN_SHIFT - 1)) & 1)));           \
        }                                                                      \
    }

#elif defined(__INTEL_COMPILER)
#define compute_tree_index(S, I)                                               \
    {                                                                          \
        size_t X = S >> TREEBIN_SHIFT;                                         \
        if (X == 0)                                                            \
            I = 0;                                                             \
        else if (X > 0xFFFF)                                                   \
            I = NTREEBINS - 1;                                                 \
        else                                                                   \
        {                                                                      \
            unsigned int K = _bit_scan_reverse (X);                            \
            I = (bindex_t) ((K << 1) +                                         \
                            ((S >> (K + (TREEBIN_SHIFT - 1)) & 1)));           \
        }                                                                      \
    }

#elif defined(_MSC_VER) && _MSC_VER >= 1300
#define compute_tree_index(S, I)                                               \
    {                                                                          \
        size_t X = S >> TREEBIN_SHIFT;                                         \
        if (X == 0)                                                            \
            I = 0;                                                             \
        else if (X > 0xFFFF)                                                   \
            I = NTREEBINS - 1;                                                 \
        else                                                                   \
        {                                                                      \
            unsigned int K;                                                    \
            _BitScanReverse ((DWORD *)&K, (DWORD)X);                           \
            I = (bindex_t) ((K << 1) +                                         \
                            ((S >> (K + (TREEBIN_SHIFT - 1)) & 1)));           \
        }                                                                      \
    }

#else /* GNUC */
#define compute_tree_index(S, I)                                               \
    {                                                                          \
        size_t X = S >> TREEBIN_SHIFT;                                         \
        if (X == 0)                                                            \
            I = 0;                                                             \
        else if (X > 0xFFFF)                                                   \
            I = NTREEBINS - 1;                                                 \
        else                                                                   \
        {                                                                      \
            unsigned int Y = (unsigned int)X;                                  \
            unsigned int N = ((Y - 0x100) >> 16) & 8;                          \
            unsigned int K = (((Y <<= N) - 0x1000) >> 16) & 4;                 \
            N += K;                                                            \
            N += K = (((Y <<= K) - 0x4000) >> 16) & 2;                         \
            K      = 14 - N + ((Y <<= K) >> 15);                               \
            I      = (K << 1) + ((S >> (K + (TREEBIN_SHIFT - 1)) & 1));        \
        }                                                                      \
    }
#endif /* GNUC */

/* Bit representing maximum resolved size in a treebin at i */
#define bit_for_tree_index(i)                                                  \
    (i == NTREEBINS - 1) ? (SIZE_T_BITSIZE - 1)                                \
                         : (((i) >> 1) + TREEBIN_SHIFT - 2)

/* Shift placing maximum resolved bit in a treebin at i as sign bit */
#define leftshift_for_tree_index(i)                                            \
    ((i == NTREEBINS - 1) ? 0 : ((SIZE_T_BITSIZE - SIZE_T_ONE) -               \
                                 (((i) >> 1) + TREEBIN_SHIFT - 2)))

/* The size of the smallest chunk held in bin with index i */
#define minsize_for_tree_index(i)                                              \
    ((SIZE_T_ONE << (((i) >> 1) + TREEBIN_SHIFT)) |                            \
     (((size_t) ((i)&SIZE_T_ONE)) << (((i) >> 1) + TREEBIN_SHIFT - 1)))

/* ------------------------ Operations on bin maps ----------------------- */

/* bit corresponding to given index */
#define idx2bit(i) ((binmap_t) (1) << (i))

/* Mark/Clear bits with given index */
#define mark_smallmap(M, i) ((M)->smallmap |= idx2bit (i))
#define clear_smallmap(M, i) ((M)->smallmap &= ~idx2bit (i))
#define smallmap_is_marked(M, i) ((M)->smallmap & idx2bit (i))

#define mark_treemap(M, i) ((M)->treemap |= idx2bit (i))
#define clear_treemap(M, i) ((M)->treemap &= ~idx2bit (i))
#define treemap_is_marked(M, i) ((M)->treemap & idx2bit (i))

/* isolate the least set bit of a bitmap */
#define least_bit(x) ((x) & -(x))

/* mask with all bits to left of least bit of x on */
#define left_bits(x) ((x << 1) | -(x << 1))

/* mask with all bits to left of or equal to least bit of x on */
#define same_or_left_bits(x) ((x) | -(x))

/* index corresponding to given bit. Use x86 asm if possible */

#if defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__))
#define compute_bit2idx(X, I)                                                  \
    {                                                                          \
        unsigned int J;                                                        \
        J = __builtin_ctz (X);                                                 \
        I = (bindex_t)J;                                                       \
    }

#elif defined(__INTEL_COMPILER)
#define compute_bit2idx(X, I)                                                  \
    {                                                                          \
        unsigned int J;                                                        \
        J = _bit_scan_forward (X);                                             \
        I = (bindex_t)J;                                                       \
    }

#elif defined(_MSC_VER) && _MSC_VER >= 1300
#define compute_bit2idx(X, I)                                                  \
    {                                                                          \
        unsigned int J;                                                        \
        _BitScanForward ((DWORD *)&J, X);                                      \
        I = (bindex_t)J;                                                       \
    }

#elif USE_BUILTIN_FFS
#define compute_bit2idx(X, I) I = ffs (X) - 1

#else
#define compute_bit2idx(X, I)                                                  \
    {                                                                          \
        unsigned int Y = X - 1;                                                \
        unsigned int K = Y >> (16 - 4) & 16;                                   \
        unsigned int N = K;                                                    \
        Y >>= K;                                                               \
        N += K = Y >> (8 - 3) & 8;                                             \
        Y >>= K;                                                               \
        N += K = Y >> (4 - 2) & 4;                                             \
        Y >>= K;                                                               \
        N += K = Y >> (2 - 1) & 2;                                             \
        Y >>= K;                                                               \
        N += K = Y >> (1 - 0) & 1;                                             \
        Y >>= K;                                                               \
        I = (bindex_t) (N + Y);                                                \
    }
#endif /* GNUC */

/* ----------------------- Runtime Check Support ------------------------- */

#if !INSECURE
/* Check if address a is at least as high as any from MORECORE or MMAP */
#define ok_address(M, a) ((char *)(a) >= (M)->least_addr)
/* Check if address of next chunk n is higher than base chunk p */
#define ok_next(p, n) ((char *)(p) < (char *)(n))
/* Check if p has inuse status */
#define ok_inuse(p) is_inuse (p)
/* Check if p has its pinuse bit on */
#define ok_pinuse(p) pinuse (p)

#else /* !INSECURE */
#define ok_address(M, a) (1)
#define ok_next(b, n) (1)
#define ok_inuse(p) (1)
#define ok_pinuse(p) (1)
#endif /* !INSECURE */

#define ok_magic(M) (1)

/* In gcc, use __builtin_expect to minimize impact of checks */
#if !INSECURE
#if defined(__GNUC__) && __GNUC__ >= 3
#define RTCHECK(e) __builtin_expect (e, 1)
#else /* GNUC */
#define RTCHECK(e) (e)
#endif /* GNUC */
#else  /* !INSECURE */
#define RTCHECK(e) (1)
#endif /* !INSECURE */

/* macros to set up inuse chunks with or without footers */

#define mark_inuse_foot(M, p, s)

/* Macros for setting head/foot of non-mmapped chunks */

/* Set cinuse bit and pinuse bit of next chunk */
#define set_inuse(M, p, s)                                                     \
    ((p)->head = (((p)->head & PINUSE_BIT) | s | CINUSE_BIT),                  \
     ((mchunkptr) (((char *)(p)) + (s)))->head |= PINUSE_BIT)

/* Set cinuse and pinuse of this chunk and pinuse of next chunk */
#define set_inuse_and_pinuse(M, p, s)                                          \
    ((p)->head = (s | PINUSE_BIT | CINUSE_BIT),                                \
     ((mchunkptr) (((char *)(p)) + (s)))->head |= PINUSE_BIT)

/* Set size, cinuse and pinuse bit of this chunk */
#define set_size_and_pinuse_of_inuse_chunk(M, p, s)                            \
    ((p)->head = (s | PINUSE_BIT | CINUSE_BIT))

/* ---------------------------- setting mparams -------------------------- */

#if LOCK_AT_FORK
static void pre_fork (void) { ACQUIRE_LOCK (&(gm)->mutex); }
static void post_fork_parent (void) { RELEASE_LOCK (&(gm)->mutex); }
static void post_fork_child (void) { INITIAL_LOCK (&(gm)->mutex); }
#endif /* LOCK_AT_FORK */

/* Initialize mparams */
static int init_mparams (void)
{
#ifdef NEED_GLOBAL_LOCK_INIT
    if (malloc_global_mutex_status <= 0)
        init_malloc_global_mutex ();
#endif

    ACQUIRE_MALLOC_GLOBAL_LOCK ();
    if (mparams.magic == 0)
    {
        size_t magic;
        size_t psize;
        size_t gsize;

#ifndef WIN32
        psize = malloc_getpagesize;
        gsize = ((DEFAULT_GRANULARITY != 0) ? DEFAULT_GRANULARITY : psize);
#else  /* WIN32 */
        {
            SYSTEM_INFO system_info;
            GetSystemInfo (&system_info);
            psize = system_info.dwPageSize;
            gsize = ((DEFAULT_GRANULARITY != 0)
                         ? DEFAULT_GRANULARITY
                         : system_info.dwAllocationGranularity);
        }
#endif /* WIN32 */

        /* Sanity-check configuration:
           size_t must be unsigned and as wide as pointer type.
           ints must be at least 4 bytes.
           alignment must be at least 8.
           Alignment, min chunk size, and page size must all be powers of 2.
        */
        if ((sizeof (size_t) != sizeof (char *)) ||
            (MAX_SIZE_T < MIN_CHUNK_SIZE) || (sizeof (int) < 4) ||
            (MALLOC_ALIGNMENT < (size_t)8U) ||
            ((MALLOC_ALIGNMENT & (MALLOC_ALIGNMENT - SIZE_T_ONE)) != 0) ||
            ((MCHUNK_SIZE & (MCHUNK_SIZE - SIZE_T_ONE)) != 0) ||
            ((gsize & (gsize - SIZE_T_ONE)) != 0) ||
            ((psize & (psize - SIZE_T_ONE)) != 0))
            ABORT;
        mparams.granularity    = gsize;
        mparams.page_size      = psize;
        mparams.mmap_threshold = DEFAULT_MMAP_THRESHOLD;
        mparams.trim_threshold = DEFAULT_TRIM_THRESHOLD;
#if MORECORE_CONTIGUOUS
        mparams.default_mflags = USE_LOCK_BIT | USE_MMAP_BIT;
#else  /* MORECORE_CONTIGUOUS */
        mparams.default_mflags =
            USE_LOCK_BIT | USE_MMAP_BIT | USE_NONCONTIGUOUS_BIT;
#endif /* MORECORE_CONTIGUOUS */

#if LOCK_AT_FORK
        pthread_atfork (&pre_fork, &post_fork_parent, &post_fork_child);
#endif

        {
#ifdef WIN32
            magic = (size_t) (GetTickCount () ^ (size_t)0x55555555U);
#elif defined(LACKS_TIME_H)
            magic = (size_t)&magic ^ (size_t)0x55555555U;
#else
            magic = (size_t) (time (0) ^ (size_t)0x55555555U);
#endif
            magic |= (size_t)8U;  /* ensure nonzero */
            magic &= ~(size_t)7U; /* improve chances of fault for bad values */
            /* Until memory modes commonly available, use volatile-write */
            (*(volatile size_t *)(&(mparams.magic))) = magic;
        }
    }

    RELEASE_MALLOC_GLOBAL_LOCK ();
    return 1;
}

/* support for mallopt */
static int change_mparam (int param_number, int value)
{
    size_t val;
    ensure_initialization ();
    val = (value == -1) ? MAX_SIZE_T : (size_t)value;
    switch (param_number)
    {
    case M_TRIM_THRESHOLD: mparams.trim_threshold = val; return 1;
    case M_GRANULARITY:
        if (val >= mparams.page_size && ((val & (val - 1)) == 0))
        {
            mparams.granularity = val;
            return 1;
        }
        else
            return 0;
    case M_MMAP_THRESHOLD: mparams.mmap_threshold = val; return 1;
    default: return 0;
    }
}

/* ----------------------------- statistics ------------------------------ */

#if !NO_MALLOC_STATS
static void internal_malloc_stats (mstate m)
{
    ensure_initialization ();
    if (!PREACTION (m))
    {
        size_t maxfp = 0;
        size_t fp    = 0;
        size_t used = 0;
        check_malloc_state (m);
        if (is_initialized (m))
        {
            msegmentptr s = &m->seg;
            maxfp         = m->max_footprint;
            fp            = m->footprint;
            used          = fp - (m->topsize + TOP_FOOT_SIZE);

            while (s != 0)
            {
                mchunkptr q = align_as_chunk (s->base);
                while (segment_holds (s, q) && q != m->top &&
                       q->head != FENCEPOST_HEAD)
                {
                    if (!is_inuse (q))
                        used -= chunksize (q);
                    q = next_chunk (q);
                }
                s = s->next;
            }
        }
        POSTACTION (m); /* drop lock */
        fprintf (stderr, "max system bytes = %10lu\n", (unsigned long)(maxfp));
        fprintf (stderr, "system bytes     = %10lu\n", (unsigned long)(fp));
        fprintf (stderr, "in use bytes     = %10lu\n", (unsigned long)(used));
    }
}
#endif /* NO_MALLOC_STATS */

/* ----------------------- Operations on smallbins ----------------------- */

/* Link a free chunk into a smallbin  */
#define insert_small_chunk(M, P, S)                                            \
    {                                                                          \
        bindex_t I  = small_index (S);                                         \
        mchunkptr B = smallbin_at (M, I);                                      \
        mchunkptr F = B;                                                       \
        assert (S >= MIN_CHUNK_SIZE);                                          \
        if (!smallmap_is_marked (M, I))                                        \
            mark_smallmap (M, I);                                              \
        else if (RTCHECK (ok_address (M, B->fd)))                              \
            F = B->fd;                                                         \
        else                                                                   \
        {                                                                      \
            CORRUPTION_ERROR_ACTION (M);                                       \
        }                                                                      \
        B->fd = P;                                                             \
        F->bk = P;                                                             \
        P->fd = F;                                                             \
        P->bk = B;                                                             \
    }

/* Unlink a chunk from a smallbin  */
#define unlink_small_chunk(M, P, S)                                            \
    {                                                                          \
        mchunkptr F = P->fd;                                                   \
        mchunkptr B = P->bk;                                                   \
        bindex_t I = small_index (S);                                          \
        assert (P != B);                                                       \
        assert (P != F);                                                       \
        assert (chunksize (P) == small_index2size (I));                        \
        if (RTCHECK (F == smallbin_at (M, I) ||                                \
                     (ok_address (M, F) && F->bk == P)))                       \
        {                                                                      \
            if (B == F)                                                        \
            {                                                                  \
                clear_smallmap (M, I);                                         \
            }                                                                  \
            else if (RTCHECK (B == smallbin_at (M, I) ||                       \
                              (ok_address (M, B) && B->fd == P)))              \
            {                                                                  \
                F->bk = B;                                                     \
                B->fd = F;                                                     \
            }                                                                  \
            else                                                               \
            {                                                                  \
                CORRUPTION_ERROR_ACTION (M);                                   \
            }                                                                  \
        }                                                                      \
        else                                                                   \
        {                                                                      \
            CORRUPTION_ERROR_ACTION (M);                                       \
        }                                                                      \
    }

/* Unlink the first chunk from a smallbin */
#define unlink_first_small_chunk(M, B, P, I)                                   \
    {                                                                          \
        mchunkptr F = P->fd;                                                   \
        assert (P != B);                                                       \
        assert (P != F);                                                       \
        assert (chunksize (P) == small_index2size (I));                        \
        if (B == F)                                                            \
        {                                                                      \
            clear_smallmap (M, I);                                             \
        }                                                                      \
        else if (RTCHECK (ok_address (M, F) && F->bk == P))                    \
        {                                                                      \
            F->bk = B;                                                         \
            B->fd = F;                                                         \
        }                                                                      \
        else                                                                   \
        {                                                                      \
            CORRUPTION_ERROR_ACTION (M);                                       \
        }                                                                      \
    }

/* Replace dv node, binning the old one */
/* Used only when dvsize known to be small */
#define replace_dv(M, P, S)                                                    \
    {                                                                          \
        size_t DVS = M->dvsize;                                                \
        assert (is_small (DVS));                                               \
        if (DVS != 0)                                                          \
        {                                                                      \
            mchunkptr DV = M->dv;                                              \
            insert_small_chunk (M, DV, DVS);                                   \
        }                                                                      \
        M->dvsize = S;                                                         \
        M->dv     = P;                                                         \
    }

/* ------------------------- Operations on trees ------------------------- */

/* Insert chunk into tree */
#define insert_large_chunk(M, X, S)                                            \
    {                                                                          \
        tbinptr * H;                                                           \
        bindex_t I;                                                            \
        compute_tree_index (S, I);                                             \
        H           = treebin_at (M, I);                                       \
        X->index    = I;                                                       \
        X->child[0] = X->child[1] = 0;                                         \
        if (!treemap_is_marked (M, I))                                         \
        {                                                                      \
            mark_treemap (M, I);                                               \
            *H        = X;                                                     \
            X->parent = (tchunkptr)H;                                          \
            X->fd = X->bk = X;                                                 \
        }                                                                      \
        else                                                                   \
        {                                                                      \
            tchunkptr T = *H;                                                  \
            size_t K = S << leftshift_for_tree_index (I);                      \
            for (;;)                                                           \
            {                                                                  \
                if (chunksize (T) != S)                                        \
                {                                                              \
                    tchunkptr * C =                                            \
                        &(T->child[(K >> (SIZE_T_BITSIZE - SIZE_T_ONE)) & 1]); \
                    K <<= 1;                                                   \
                    if (*C != 0)                                               \
                        T = *C;                                                \
                    else if (RTCHECK (ok_address (M, C)))                      \
                    {                                                          \
                        *C        = X;                                         \
                        X->parent = T;                                         \
                        X->fd = X->bk = X;                                     \
                        break;                                                 \
                    }                                                          \
                    else                                                       \
                    {                                                          \
                        CORRUPTION_ERROR_ACTION (M);                           \
                        break;                                                 \
                    }                                                          \
                }                                                              \
                else                                                           \
                {                                                              \
                    tchunkptr F = T->fd;                                       \
                    if (RTCHECK (ok_address (M, T) && ok_address (M, F)))      \
                    {                                                          \
                        T->fd = F->bk = X;                                     \
                        X->fd     = F;                                         \
                        X->bk     = T;                                         \
                        X->parent = 0;                                         \
                        break;                                                 \
                    }                                                          \
                    else                                                       \
                    {                                                          \
                        CORRUPTION_ERROR_ACTION (M);                           \
                        break;                                                 \
                    }                                                          \
                }                                                              \
            }                                                                  \
        }                                                                      \
    }

#define unlink_large_chunk(M, X)                                               \
    {                                                                          \
        tchunkptr XP = X->parent;                                              \
        tchunkptr R;                                                           \
        if (X->bk != X)                                                        \
        {                                                                      \
            tchunkptr F = X->fd;                                               \
            R = X->bk;                                                         \
            if (RTCHECK (ok_address (M, F) && F->bk == X && R->fd == X))       \
            {                                                                  \
                F->bk = R;                                                     \
                R->fd = F;                                                     \
            }                                                                  \
            else                                                               \
            {                                                                  \
                CORRUPTION_ERROR_ACTION (M);                                   \
            }                                                                  \
        }                                                                      \
        else                                                                   \
        {                                                                      \
            tchunkptr * RP;                                                    \
            if (((R = *(RP = &(X->child[1]))) != 0) ||                         \
                ((R = *(RP = &(X->child[0]))) != 0))                           \
            {                                                                  \
                tchunkptr * CP;                                                \
                while ((*(CP = &(R->child[1])) != 0) ||                        \
                       (*(CP = &(R->child[0])) != 0))                          \
                {                                                              \
                    R = *(RP = CP);                                            \
                }                                                              \
                if (RTCHECK (ok_address (M, RP)))                              \
                    *RP = 0;                                                   \
                else                                                           \
                {                                                              \
                    CORRUPTION_ERROR_ACTION (M);                               \
                }                                                              \
            }                                                                  \
        }                                                                      \
        if (XP != 0)                                                           \
        {                                                                      \
            tbinptr * H = treebin_at (M, X->index);                            \
            if (X == *H)                                                       \
            {                                                                  \
                if ((*H = R) == 0)                                             \
                    clear_treemap (M, X->index);                               \
            }                                                                  \
            else if (RTCHECK (ok_address (M, XP)))                             \
            {                                                                  \
                if (XP->child[0] == X)                                         \
                    XP->child[0] = R;                                          \
                else                                                           \
                    XP->child[1] = R;                                          \
            }                                                                  \
            else                                                               \
                CORRUPTION_ERROR_ACTION (M);                                   \
            if (R != 0)                                                        \
            {                                                                  \
                if (RTCHECK (ok_address (M, R)))                               \
                {                                                              \
                    tchunkptr C0, C1;                                          \
                    R->parent = XP;                                            \
                    if ((C0 = X->child[0]) != 0)                               \
                    {                                                          \
                        if (RTCHECK (ok_address (M, C0)))                      \
                        {                                                      \
                            R->child[0] = C0;                                  \
                            C0->parent  = R;                                   \
                        }                                                      \
                        else                                                   \
                            CORRUPTION_ERROR_ACTION (M);                       \
                    }                                                          \
                    if ((C1 = X->child[1]) != 0)                               \
                    {                                                          \
                        if (RTCHECK (ok_address (M, C1)))                      \
                        {                                                      \
                            R->child[1] = C1;                                  \
                            C1->parent  = R;                                   \
                        }                                                      \
                        else                                                   \
                            CORRUPTION_ERROR_ACTION (M);                       \
                    }                                                          \
                }                                                              \
                else                                                           \
                    CORRUPTION_ERROR_ACTION (M);                               \
            }                                                                  \
        }                                                                      \
    }

/* Relays to large vs small bin operations */

#define insert_chunk(M, P, S)                                                  \
    if (is_small (S))                                                          \
        insert_small_chunk (M, P, S) else                                      \
        {                                                                      \
            tchunkptr TP = (tchunkptr) (P);                                    \
            insert_large_chunk (M, TP, S);                                     \
        }

#define unlink_chunk(M, P, S)                                                  \
    if (is_small (S))                                                          \
        unlink_small_chunk (M, P, S) else                                      \
        {                                                                      \
            tchunkptr TP = (tchunkptr) (P);                                    \
            unlink_large_chunk (M, TP);                                        \
        }

/* Relays to internal calls to malloc/free from realloc, memalign etc */

#define internal_malloc(m, b) mspace_malloc (m, b)
#define internal_free(m, mem) mspace_free (m, mem);

/* -----------------------  Direct-mmapping chunks ----------------------- */

/* Malloc using mmap */
static void * mmap_alloc (mstate m, size_t nb)
{
    size_t mmsize = mmap_align (nb + SIX_SIZE_T_SIZES + CHUNK_ALIGN_MASK);
    if (m->footprint_limit != 0)
    {
        size_t fp = m->footprint + mmsize;
        if (fp <= m->footprint || fp > m->footprint_limit)
            return 0;
    }
    if (mmsize > nb)
    { /* Check for wrap around 0 */
        char * mm = (char *)(CALL_DIRECT_MMAP (mmsize));
        if (mm != CMFAIL)
        {
            size_t offset = align_offset (chunk2mem (mm));
            size_t psize  = mmsize - offset - MMAP_FOOT_PAD;
            mchunkptr p   = (mchunkptr) (mm + offset);
            p->prev_foot  = offset;
            p->head = psize;
            mark_inuse_foot (m, p, psize);
            chunk_plus_offset (p, psize)->head = FENCEPOST_HEAD;
            chunk_plus_offset (p, psize + SIZE_T_SIZE)->head = 0;

            if (m->least_addr == 0 || mm < m->least_addr)
                m->least_addr = mm;
            if ((m->footprint += mmsize) > m->max_footprint)
                m->max_footprint = m->footprint;
            assert (is_aligned (chunk2mem (p)));
            check_mmapped_chunk (m, p);
            return chunk2mem (p);
        }
    }
    return 0;
}

/* Realloc using mmap */
static mchunkptr mmap_resize (mstate m, mchunkptr oldp, size_t nb, int flags)
{
    size_t oldsize = chunksize (oldp);
    (void)flags;       /* placate people compiling -Wunused */
    if (is_small (nb)) /* Can't shrink mmap regions below small size */
        return 0;
    /* Keep old chunk if big enough but not too big */
    if (oldsize >= nb + SIZE_T_SIZE &&
        (oldsize - nb) <= (mparams.granularity << 1))
        return oldp;
    else
    {
        size_t offset    = oldp->prev_foot;
        size_t oldmmsize = oldsize + offset + MMAP_FOOT_PAD;
        size_t newmmsize =
            mmap_align (nb + SIX_SIZE_T_SIZES + CHUNK_ALIGN_MASK);
        char * cp = (char *)CALL_MREMAP ((char *)oldp - offset, oldmmsize,
                                         newmmsize, flags);
        if (cp != CMFAIL)
        {
            mchunkptr newp = (mchunkptr) (cp + offset);
            size_t psize   = newmmsize - offset - MMAP_FOOT_PAD;
            newp->head = psize;
            mark_inuse_foot (m, newp, psize);
            chunk_plus_offset (newp, psize)->head = FENCEPOST_HEAD;
            chunk_plus_offset (newp, psize + SIZE_T_SIZE)->head = 0;

            if (cp < m->least_addr)
                m->least_addr = cp;
            if ((m->footprint += newmmsize - oldmmsize) > m->max_footprint)
                m->max_footprint = m->footprint;
            check_mmapped_chunk (m, newp);
            return newp;
        }
    }
    return 0;
}

/* -------------------------- mspace management -------------------------- */

/* Initialize top chunk and its size */
static void init_top (mstate m, mchunkptr p, size_t psize)
{
    /* Ensure alignment */
    size_t offset = align_offset (chunk2mem (p));
    p             = (mchunkptr) ((char *)p + offset);
    psize -= offset;

    m->top     = p;
    m->topsize = psize;
    p->head    = psize | PINUSE_BIT;
    /* set size of fake trailing chunk holding overhead space only once */
    chunk_plus_offset (p, psize)->head = TOP_FOOT_SIZE;
    m->trim_check = mparams.trim_threshold; /* reset on each update */
}

/* Initialize bins for a new mstate that is otherwise zeroed out */
static void init_bins (mstate m)
{
    /* Establish circular links for smallbins */
    bindex_t i;
    for (i = 0; i < NSMALLBINS; ++i)
    {
        sbinptr bin = smallbin_at (m, i);
        bin->fd = bin->bk = bin;
    }
}

/* Allocate chunk and prepend remainder with chunk in successor base. */
static void * prepend_alloc (mstate m, char * newbase, char * oldbase,
                             size_t nb)
{
    mchunkptr p        = align_as_chunk (newbase);
    mchunkptr oldfirst = align_as_chunk (oldbase);
    size_t psize       = (char *)oldfirst - (char *)p;
    mchunkptr q        = chunk_plus_offset (p, nb);
    size_t qsize = psize - nb;
    set_size_and_pinuse_of_inuse_chunk (m, p, nb);

    assert ((char *)oldfirst > (char *)q);
    assert (pinuse (oldfirst));
    assert (qsize >= MIN_CHUNK_SIZE);

    /* consolidate remainder with first chunk of old base */
    if (oldfirst == m->top)
    {
        size_t tsize = m->topsize += qsize;
        m->top       = q;
        q->head = tsize | PINUSE_BIT;
        check_top_chunk (m, q);
    }
    else if (oldfirst == m->dv)
    {
        size_t dsize = m->dvsize += qsize;
        m->dv = q;
        set_size_and_pinuse_of_free_chunk (q, dsize);
    }
    else
    {
        if (!is_inuse (oldfirst))
        {
            size_t nsize = chunksize (oldfirst);
            unlink_chunk (m, oldfirst, nsize);
            oldfirst = chunk_plus_offset (oldfirst, nsize);
            qsize += nsize;
        }
        set_free_with_pinuse (q, qsize, oldfirst);
        insert_chunk (m, q, qsize);
        check_free_chunk (m, q);
    }

    check_malloced_chunk (m, chunk2mem (p), nb);
    return chunk2mem (p);
}

/* Add a segment to hold a new noncontiguous region */
static void add_segment (mstate m, char * tbase, size_t tsize, flag_t mmapped)
{
    /* Determine locations and sizes of segment, fenceposts, old top */
    char * old_top    = (char *)m->top;
    msegmentptr oldsp = segment_holding (m, old_top);
    char * old_end    = oldsp->base + oldsp->size;
    size_t ssize      = pad_request (sizeof (struct malloc_segment));
    char * rawsp      = old_end - (ssize + FOUR_SIZE_T_SIZES + CHUNK_ALIGN_MASK);
    size_t offset     = align_offset (chunk2mem (rawsp));
    char * asp        = rawsp + offset;
    char * csp        = (asp < (old_top + MIN_CHUNK_SIZE)) ? old_top : asp;
    mchunkptr sp      = (mchunkptr)csp;
    msegmentptr ss    = (msegmentptr) (chunk2mem (sp));
    mchunkptr tnext   = chunk_plus_offset (sp, ssize);
    mchunkptr p       = tnext;
    int nfences       = 0;

    /* reset top to new space */
    init_top (m, (mchunkptr)tbase, tsize - TOP_FOOT_SIZE);

    /* Set up segment record */
    assert (is_aligned (ss));
    set_size_and_pinuse_of_inuse_chunk (m, sp, ssize);
    *ss           = m->seg; /* Push current record */
    m->seg.base   = tbase;
    m->seg.size   = tsize;
    m->seg.sflags = mmapped;
    m->seg.next   = ss;

    /* Insert trailing fenceposts */
    for (;;)
    {
        mchunkptr nextp = chunk_plus_offset (p, SIZE_T_SIZE);
        p->head         = FENCEPOST_HEAD;
        ++nfences;
        if ((char *)(&(nextp->head)) < old_end)
            p = nextp;
        else
            break;
    }
    assert (nfences >= 2);

    /* Insert the rest of old top into a bin as an ordinary free chunk */
    if (csp != old_top)
    {
        mchunkptr q  = (mchunkptr)old_top;
        size_t psize = csp - old_top;
        mchunkptr tn = chunk_plus_offset (q, psize);
        set_free_with_pinuse (q, psize, tn);
        insert_chunk (m, q, psize);
    }

    check_top_chunk (m, m->top);
}

/* -------------------------- System allocation -------------------------- */

/* Get memory from system using MORECORE or MMAP */
static void * sys_alloc (mstate m, size_t nb)
{
    char * tbase     = CMFAIL;
    size_t tsize     = 0;
    flag_t mmap_flag = 0;
    size_t asize; /* allocation size */

    ensure_initialization ();

    /* Directly map large chunks, but only if already initialized */
    if (use_mmap (m) && nb >= mparams.mmap_threshold && m->topsize != 0)
    {
        void * mem = mmap_alloc (m, nb);
        if (mem != 0)
            return mem;
    }

    asize = granularity_align (nb + SYS_ALLOC_PADDING);
    if (asize <= nb)
        return 0; /* wraparound */
    if (m->footprint_limit != 0)
    {
        size_t fp = m->footprint + asize;
        if (fp <= m->footprint || fp > m->footprint_limit)
            return 0;
    }

    if (MORECORE_CONTIGUOUS && !use_noncontiguous (m))
    {
        char * br    = CMFAIL;
        size_t ssize = asize; /* sbrk call size */
        msegmentptr ss =
            (m->top == 0) ? 0 : segment_holding (m, (char *)m->top);
        ACQUIRE_MALLOC_GLOBAL_LOCK ();

        if (ss == 0)
        { /* First time through or recovery */
            char * base = (char *)CALL_MORECORE (0);
            if (base != CMFAIL)
            {
                size_t fp;
                /* Adjust to end on a page boundary */
                if (!is_page_aligned (base))
                    ssize += (page_align ((size_t)base) - (size_t)base);
                fp = m->footprint + ssize; /* recheck limits */
                if (ssize > nb && ssize < HALF_MAX_SIZE_T &&
                    (m->footprint_limit == 0 ||
                     (fp > m->footprint && fp <= m->footprint_limit)) &&
                    (br = (char *)(CALL_MORECORE (ssize))) == base)
                {
                    tbase = base;
                    tsize = ssize;
                }
            }
        }
        else
        {
            /* Subtract out existing available top space from MORECORE request.
             */
            ssize = granularity_align (nb - m->topsize + SYS_ALLOC_PADDING);
            /* Use mem here only if it did continuously extend old space */
            if (ssize < HALF_MAX_SIZE_T &&
                (br = (char *)(CALL_MORECORE (ssize))) == ss->base + ss->size)
            {
                tbase = br;
                tsize = ssize;
            }
        }

        if (tbase == CMFAIL)
        { /* Cope with partial failure */
            if (br != CMFAIL)
            { /* Try to use/extend the space we did get */
                if (ssize < HALF_MAX_SIZE_T && ssize < nb + SYS_ALLOC_PADDING)
                {
                    size_t esize =
                        granularity_align (nb + SYS_ALLOC_PADDING - ssize);
                    if (esize < HALF_MAX_SIZE_T)
                    {
                        char * end = (char *)CALL_MORECORE (esize);
                        if (end != CMFAIL)
                            ssize += esize;
                        else
                        { /* Can't use; try to release */
                            (void)CALL_MORECORE (-ssize);
                            br = CMFAIL;
                        }
                    }
                }
            }
            if (br != CMFAIL)
            { /* Use the space we did get */
                tbase = br;
                tsize = ssize;
            }
            else
                disable_contiguous (
                    m); /* Don't try contiguous path in the future */
        }

        RELEASE_MALLOC_GLOBAL_LOCK ();
    }

    if (HAVE_MMAP && tbase == CMFAIL)
    { /* Try MMAP */
        char * mp = (char *)(CALL_MMAP (asize));
        if (mp != CMFAIL)
        {
            tbase     = mp;
            tsize     = asize;
            mmap_flag = USE_MMAP_BIT;
        }
    }

    if (HAVE_MORECORE && tbase == CMFAIL)
    { /* Try noncontiguous MORECORE */
        if (asize < HALF_MAX_SIZE_T)
        {
            char * br  = CMFAIL;
            char * end = CMFAIL;
            ACQUIRE_MALLOC_GLOBAL_LOCK ();
            br  = (char *)(CALL_MORECORE (asize));
            end = (char *)(CALL_MORECORE (0));
            RELEASE_MALLOC_GLOBAL_LOCK ();
            if (br != CMFAIL && end != CMFAIL && br < end)
            {
                size_t ssize = end - br;
                if (ssize > nb + TOP_FOOT_SIZE)
                {
                    tbase = br;
                    tsize = ssize;
                }
            }
        }
    }

    if (tbase != CMFAIL)
    {

        if ((m->footprint += tsize) > m->max_footprint)
            m->max_footprint = m->footprint;

        if (!is_initialized (m))
        { /* first-time initialization */
            if (m->least_addr == 0 || tbase < m->least_addr)
                m->least_addr = tbase;
            m->seg.base       = tbase;
            m->seg.size       = tsize;
            m->seg.sflags     = mmap_flag;
            m->magic          = mparams.magic;
            m->release_checks = MAX_RELEASE_CHECK_RATE;
            init_bins (m);
            {
                /* Offset top by embedded malloc_state */
                mchunkptr mn = next_chunk (mem2chunk (m));
                init_top (m, mn, (size_t) ((tbase + tsize) - (char *)mn) -
                                     TOP_FOOT_SIZE);
            }
        }

        else
        {
            /* Try to merge with an existing segment */
            msegmentptr sp = &m->seg;
            /* Only consider most recent segment if traversal suppressed */
            while (sp != 0 && tbase != sp->base + sp->size)
                sp = (NO_SEGMENT_TRAVERSAL) ? 0 : sp->next;
            if (sp != 0 && !is_extern_segment (sp) &&
                (sp->sflags & USE_MMAP_BIT) == mmap_flag &&
                segment_holds (sp, m->top))
            { /* append */
                sp->size += tsize;
                init_top (m, m->top, m->topsize + tsize);
            }
            else
            {
                if (tbase < m->least_addr)
                    m->least_addr = tbase;
                sp = &m->seg;
                while (sp != 0 && sp->base != tbase + tsize)
                    sp = (NO_SEGMENT_TRAVERSAL) ? 0 : sp->next;
                if (sp != 0 && !is_extern_segment (sp) &&
                    (sp->sflags & USE_MMAP_BIT) == mmap_flag)
                {
                    char * oldbase = sp->base;
                    sp->base       = tbase;
                    sp->size += tsize;
                    return prepend_alloc (m, tbase, oldbase, nb);
                }
                else
                    add_segment (m, tbase, tsize, mmap_flag);
            }
        }

        if (nb < m->topsize)
        { /* Allocate from new or extended top space */
            size_t rsize = m->topsize -= nb;
            mchunkptr p  = m->top;
            mchunkptr r = m->top = chunk_plus_offset (p, nb);
            r->head = rsize | PINUSE_BIT;
            set_size_and_pinuse_of_inuse_chunk (m, p, nb);
            check_top_chunk (m, m->top);
            check_malloced_chunk (m, chunk2mem (p), nb);
            return chunk2mem (p);
        }
    }

    MALLOC_FAILURE_ACTION;
    return 0;
}

/* -----------------------  system deallocation -------------------------- */

/* Unmap and unlink any mmapped segments that don't contain used chunks */
static size_t release_unused_segments (mstate m)
{
    size_t released  = 0;
    int nsegs        = 0;
    msegmentptr pred = &m->seg;
    msegmentptr sp = pred->next;
    while (sp != 0)
    {
        char * base      = sp->base;
        size_t size      = sp->size;
        msegmentptr next = sp->next;
        ++nsegs;
        if (is_mmapped_segment (sp) && !is_extern_segment (sp))
        {
            mchunkptr p  = align_as_chunk (base);
            size_t psize = chunksize (p);
            /* Can unmap if first chunk holds entire segment and not pinned */
            if (!is_inuse (p) &&
                (char *)p + psize >= base + size - TOP_FOOT_SIZE)
            {
                tchunkptr tp = (tchunkptr)p;
                assert (segment_holds (sp, (char *)sp));
                if (p == m->dv)
                {
                    m->dv     = 0;
                    m->dvsize = 0;
                }
                else
                {
                    unlink_large_chunk (m, tp);
                }
                if (CALL_MUNMAP (base, size) == 0)
                {
                    released += size;
                    m->footprint -= size;
                    /* unlink obsoleted record */
                    sp       = pred;
                    sp->next = next;
                }
                else
                { /* back out if cannot unmap */
                    insert_large_chunk (m, tp, psize);
                }
            }
        }
        if (NO_SEGMENT_TRAVERSAL) /* scan only first segment */
            break;
        pred = sp;
        sp   = next;
    }
    /* Reset check counter */
    m->release_checks = (((size_t)nsegs > (size_t)MAX_RELEASE_CHECK_RATE)
                             ? (size_t)nsegs
                             : (size_t)MAX_RELEASE_CHECK_RATE);
    return released;
}

static int sys_trim (mstate m, size_t pad)
{
    size_t released = 0;
    ensure_initialization ();
    if (pad < MAX_REQUEST && is_initialized (m))
    {
        pad += TOP_FOOT_SIZE; /* ensure enough room for segment overhead */

        if (m->topsize > pad)
        {
            /* Shrink top space in granularity-size units, keeping at least one
             */
            size_t unit = mparams.granularity;
            size_t extra =
                ((m->topsize - pad + (unit - SIZE_T_ONE)) / unit - SIZE_T_ONE) *
                unit;
            msegmentptr sp = segment_holding (m, (char *)m->top);

            if (!is_extern_segment (sp))
            {
                if (is_mmapped_segment (sp))
                {
                    if (HAVE_MMAP && sp->size >= extra &&
                        !has_segment_link (m, sp))
                    { /* can't shrink if pinned */
                        size_t newsize = sp->size - extra;
                        (void)newsize; /* placate people compiling
                                          -Wunused-variable */
                        /* Prefer mremap, fall back to munmap */
                        if ((CALL_MREMAP (sp->base, sp->size, newsize, 0) !=
                             MFAIL) ||
                            (CALL_MUNMAP (sp->base + newsize, extra) == 0))
                        {
                            released = extra;
                        }
                    }
                }
                else if (HAVE_MORECORE)
                {
                    if (extra >= HALF_MAX_SIZE_T) /* Avoid wrapping negative */
                        extra = (HALF_MAX_SIZE_T) + SIZE_T_ONE - unit;
                    ACQUIRE_MALLOC_GLOBAL_LOCK ();
                    {
                        /* Make sure end of memory is where we last set it. */
                        char * old_br = (char *)(CALL_MORECORE (0));
                        if (old_br == sp->base + sp->size)
                        {
                            char * rel_br = (char *)(CALL_MORECORE (-extra));
                            char * new_br = (char *)(CALL_MORECORE (0));
                            if (rel_br != CMFAIL && new_br < old_br)
                                released = old_br - new_br;
                        }
                    }
                    RELEASE_MALLOC_GLOBAL_LOCK ();
                }
            }

            if (released != 0)
            {
                sp->size -= released;
                m->footprint -= released;
                init_top (m, m->top, m->topsize - released);
                check_top_chunk (m, m->top);
            }
        }

        /* Unmap any unused mmapped segments */
        if (HAVE_MMAP)
            released += release_unused_segments (m);

        /* On failure, disable autotrim to avoid repeated failed future calls */
        if (released == 0 && m->topsize > m->trim_check)
            m->trim_check = MAX_SIZE_T;
    }

    return (released != 0) ? 1 : 0;
}

/* Consolidate and bin a chunk. Differs from exported versions
   of free mainly in that the chunk need not be marked as inuse.
*/
static void dispose_chunk (mstate m, mchunkptr p, size_t psize)
{
    mchunkptr next = chunk_plus_offset (p, psize);
    if (!pinuse (p))
    {
        mchunkptr prev;
        size_t prevsize = p->prev_foot;
        if (is_mmapped (p))
        {
            psize += prevsize + MMAP_FOOT_PAD;
            if (CALL_MUNMAP ((char *)p - prevsize, psize) == 0)
                m->footprint -= psize;
            return;
        }
        prev = chunk_minus_offset (p, prevsize);
        psize += prevsize;
        p = prev;
        if (RTCHECK (ok_address (m, prev)))
        { /* consolidate backward */
            if (p != m->dv)
            {
                unlink_chunk (m, p, prevsize);
            }
            else if ((next->head & INUSE_BITS) == INUSE_BITS)
            {
                m->dvsize = psize;
                set_free_with_pinuse (p, psize, next);
                return;
            }
        }
        else
        {
            CORRUPTION_ERROR_ACTION (m);
            return;
        }
    }
    if (RTCHECK (ok_address (m, next)))
    {
        if (!cinuse (next))
        { /* consolidate forward */
            if (next == m->top)
            {
                size_t tsize = m->topsize += psize;
                m->top       = p;
                p->head = tsize | PINUSE_BIT;
                if (p == m->dv)
                {
                    m->dv     = 0;
                    m->dvsize = 0;
                }
                return;
            }
            else if (next == m->dv)
            {
                size_t dsize = m->dvsize += psize;
                m->dv = p;
                set_size_and_pinuse_of_free_chunk (p, dsize);
                return;
            }
            else
            {
                size_t nsize = chunksize (next);
                psize += nsize;
                unlink_chunk (m, next, nsize);
                set_size_and_pinuse_of_free_chunk (p, psize);
                if (p == m->dv)
                {
                    m->dvsize = psize;
                    return;
                }
            }
        }
        else
        {
            set_free_with_pinuse (p, psize, next);
        }
        insert_chunk (m, p, psize);
    }
    else
    {
        CORRUPTION_ERROR_ACTION (m);
    }
}

/* ---------------------------- malloc --------------------------- */

/* allocate a large request from the best fitting chunk in a treebin */
static void * tmalloc_large (mstate m, size_t nb)
{
    tchunkptr v  = 0;
    size_t rsize = -nb; /* Unsigned negation */
    tchunkptr t;
    bindex_t idx;
    compute_tree_index (nb, idx);
    if ((t = *treebin_at (m, idx)) != 0)
    {
        /* Traverse tree for this bin looking for node with size == nb */
        size_t sizebits = nb << leftshift_for_tree_index (idx);
        tchunkptr rst = 0; /* The deepest untaken right subtree */
        for (;;)
        {
            tchunkptr rt;
            size_t trem = chunksize (t) - nb;
            if (trem < rsize)
            {
                v = t;
                if ((rsize = trem) == 0)
                    break;
            }
            rt = t->child[1];
            t = t->child[(sizebits >> (SIZE_T_BITSIZE - SIZE_T_ONE)) & 1];
            if (rt != 0 && rt != t)
                rst = rt;
            if (t == 0)
            {
                t = rst; /* set t to least subtree holding sizes > nb */
                break;
            }
            sizebits <<= 1;
        }
    }
    if (t == 0 && v == 0)
    { /* set t to root of next non-empty treebin */
        binmap_t leftbits = left_bits (idx2bit (idx)) & m->treemap;
        if (leftbits != 0)
        {
            bindex_t i;
            binmap_t leastbit = least_bit (leftbits);
            compute_bit2idx (leastbit, i);
            t = *treebin_at (m, i);
        }
    }

    while (t != 0)
    { /* find smallest of tree or subtree */
        size_t trem = chunksize (t) - nb;
        if (trem < rsize)
        {
            rsize = trem;
            v     = t;
        }
        t = leftmost_child (t);
    }

    /*  If dv is a better fit, return 0 so malloc will use it */
    if (v != 0 && rsize < (size_t) (m->dvsize - nb))
    {
        if (RTCHECK (ok_address (m, v)))
        { /* split */
            mchunkptr r = chunk_plus_offset (v, nb);
            assert (chunksize (v) == rsize + nb);
            if (RTCHECK (ok_next (v, r)))
            {
                unlink_large_chunk (m, v);
                if (rsize < MIN_CHUNK_SIZE)
                    set_inuse_and_pinuse (m, v, (rsize + nb));
                else
                {
                    set_size_and_pinuse_of_inuse_chunk (m, v, nb);
                    set_size_and_pinuse_of_free_chunk (r, rsize);
                    insert_chunk (m, r, rsize);
                }
                return chunk2mem (v);
            }
        }
        CORRUPTION_ERROR_ACTION (m);
    }
    return 0;
}

/* allocate a small request from the best fitting chunk in a treebin */
static void * tmalloc_small (mstate m, size_t nb)
{
    tchunkptr t, v;
    size_t rsize;
    bindex_t i;
    binmap_t leastbit = least_bit (m->treemap);
    compute_bit2idx (leastbit, i);
    v = t = *treebin_at (m, i);
    rsize = chunksize (t) - nb;

    while ((t = leftmost_child (t)) != 0)
    {
        size_t trem = chunksize (t) - nb;
        if (trem < rsize)
        {
            rsize = trem;
            v     = t;
        }
    }

    if (RTCHECK (ok_address (m, v)))
    {
        mchunkptr r = chunk_plus_offset (v, nb);
        assert (chunksize (v) == rsize + nb);
        if (RTCHECK (ok_next (v, r)))
        {
            unlink_large_chunk (m, v);
            if (rsize < MIN_CHUNK_SIZE)
                set_inuse_and_pinuse (m, v, (rsize + nb));
            else
            {
                set_size_and_pinuse_of_inuse_chunk (m, v, nb);
                set_size_and_pinuse_of_free_chunk (r, rsize);
                replace_dv (m, r, rsize);
            }
            return chunk2mem (v);
        }
    }

    CORRUPTION_ERROR_ACTION (m);
    return 0;
}

/* ------------ Internal support for realloc, memalign, etc -------------- */

/* Try to realloc; only in-place unless can_move true */
static mchunkptr try_realloc_chunk (mstate m, mchunkptr p, size_t nb,
                                    int can_move)
{
    mchunkptr newp = 0;
    size_t oldsize = chunksize (p);
    mchunkptr next = chunk_plus_offset (p, oldsize);
    if (RTCHECK (ok_address (m, p) && ok_inuse (p) && ok_next (p, next) &&
                 ok_pinuse (next)))
    {
        if (is_mmapped (p))
        {
            newp = mmap_resize (m, p, nb, can_move);
        }
        else if (oldsize >= nb)
        { /* already big enough */
            size_t rsize = oldsize - nb;
            if (rsize >= MIN_CHUNK_SIZE)
            { /* split off remainder */
                mchunkptr r = chunk_plus_offset (p, nb);
                set_inuse (m, p, nb);
                set_inuse (m, r, rsize);
                dispose_chunk (m, r, rsize);
            }
            newp = p;
        }
        else if (next == m->top)
        { /* extend into top */
            if (oldsize + m->topsize > nb)
            {
                size_t newsize    = oldsize + m->topsize;
                size_t newtopsize = newsize - nb;
                mchunkptr newtop = chunk_plus_offset (p, nb);
                set_inuse (m, p, nb);
                newtop->head = newtopsize | PINUSE_BIT;
                m->top       = newtop;
                m->topsize   = newtopsize;
                newp         = p;
            }
        }
        else if (next == m->dv)
        { /* extend into dv */
            size_t dvs = m->dvsize;
            if (oldsize + dvs >= nb)
            {
                size_t dsize = oldsize + dvs - nb;
                if (dsize >= MIN_CHUNK_SIZE)
                {
                    mchunkptr r = chunk_plus_offset (p, nb);
                    mchunkptr n = chunk_plus_offset (r, dsize);
                    set_inuse (m, p, nb);
                    set_size_and_pinuse_of_free_chunk (r, dsize);
                    clear_pinuse (n);
                    m->dvsize = dsize;
                    m->dv     = r;
                }
                else
                { /* exhaust dv */
                    size_t newsize = oldsize + dvs;
                    set_inuse (m, p, newsize);
                    m->dvsize = 0;
                    m->dv     = 0;
                }
                newp = p;
            }
        }
        else if (!cinuse (next))
        { /* extend into next free chunk */
            size_t nextsize = chunksize (next);
            if (oldsize + nextsize >= nb)
            {
                size_t rsize = oldsize + nextsize - nb;
                unlink_chunk (m, next, nextsize);
                if (rsize < MIN_CHUNK_SIZE)
                {
                    size_t newsize = oldsize + nextsize;
                    set_inuse (m, p, newsize);
                }
                else
                {
                    mchunkptr r = chunk_plus_offset (p, nb);
                    set_inuse (m, p, nb);
                    set_inuse (m, r, rsize);
                    dispose_chunk (m, r, rsize);
                }
                newp = p;
            }
        }
    }
    else
    {
        USAGE_ERROR_ACTION (m, chunk2mem (p));
    }
    return newp;
}

static void * internal_memalign (mstate m, size_t alignment, size_t bytes)
{
    void * mem = 0;
    if (alignment < MIN_CHUNK_SIZE) /* must be at least a minimum chunk size */
        alignment = MIN_CHUNK_SIZE;
    if ((alignment & (alignment - SIZE_T_ONE)) != 0)
    { /* Ensure a power of 2 */
        size_t a = MALLOC_ALIGNMENT << 1;
        while (a < alignment)
            a <<= 1;
        alignment = a;
    }
    if (bytes >= MAX_REQUEST - alignment)
    {
        if (m != 0)
        { /* Test isn't needed but avoids compiler warning */
            MALLOC_FAILURE_ACTION;
        }
    }
    else
    {
        size_t nb  = request2size (bytes);
        size_t req = nb + alignment + MIN_CHUNK_SIZE - CHUNK_OVERHEAD;
        mem = internal_malloc (m, req);
        if (mem != 0)
        {
            mchunkptr p = mem2chunk (mem);
            if (PREACTION (m))
                return 0;
            if ((((size_t) (mem)) & (alignment - 1)) != 0)
            {   /* misaligned */
                /*
                  Find an aligned spot inside chunk.  Since we need to give
                  back leading space in a chunk of at least MIN_CHUNK_SIZE, if
                  the first calculation places us at a spot with less than
                  MIN_CHUNK_SIZE leader, we can move to the next aligned spot.
                  We've allocated enough total room so that this is always
                  possible.
                */
                char * br = (char *)mem2chunk ((size_t) (
                    ((size_t) ((char *)mem + alignment - SIZE_T_ONE)) &
                    -alignment));
                char * pos = ((size_t) (br - (char *)(p)) >= MIN_CHUNK_SIZE)
                                 ? br
                                 : br + alignment;
                mchunkptr newp  = (mchunkptr)pos;
                size_t leadsize = pos - (char *)(p);
                size_t newsize  = chunksize (p) - leadsize;

                if (is_mmapped (p))
                { /* For mmapped chunks, just adjust offset */
                    newp->prev_foot = p->prev_foot + leadsize;
                    newp->head      = newsize;
                }
                else
                { /* Otherwise, give back leader, use the rest */
                    set_inuse (m, newp, newsize);
                    set_inuse (m, p, leadsize);
                    dispose_chunk (m, p, leadsize);
                }
                p = newp;
            }

            /* Give back spare room at the end */
            if (!is_mmapped (p))
            {
                size_t size = chunksize (p);
                if (size > nb + MIN_CHUNK_SIZE)
                {
                    size_t remainder_size = size - nb;
                    mchunkptr remainder = chunk_plus_offset (p, nb);
                    set_inuse (m, p, nb);
                    set_inuse (m, remainder, remainder_size);
                    dispose_chunk (m, remainder, remainder_size);
                }
            }

            mem = chunk2mem (p);
            assert (chunksize (p) >= nb);
            assert (((size_t)mem & (alignment - 1)) == 0);
            check_inuse_chunk (m, p);
            POSTACTION (m);
        }
    }
    return mem;
}

/* Try to free all pointers in the given array.
   Note: this could be made faster, by delaying consolidation,
   at the price of disabling some user integrity checks, We
   still optimize some consolidations by combining adjacent
   chunks before freeing, which will occur often if allocated
   with ialloc or the array is sorted.
*/
static size_t internal_bulk_free (mstate m, void * array[], size_t nelem)
{
    size_t unfreed = 0;
    if (!PREACTION (m))
    {
        void ** a;
        void ** fence = &(array[nelem]);
        for (a = array; a != fence; ++a)
        {
            void * mem = *a;
            if (mem != 0)
            {
                mchunkptr p  = mem2chunk (mem);
                size_t psize = chunksize (p);
                check_inuse_chunk (m, p);
                *a = 0;
                if (RTCHECK (ok_address (m, p) && ok_inuse (p)))
                {
                    void ** b      = a + 1; /* try to merge with next chunk */
                    mchunkptr next = next_chunk (p);
                    if (b != fence && *b == chunk2mem (next))
                    {
                        size_t newsize = chunksize (next) + psize;
                        set_inuse (m, p, newsize);
                        *b = chunk2mem (p);
                    }
                    else
                        dispose_chunk (m, p, psize);
                }
                else
                {
                    CORRUPTION_ERROR_ACTION (m);
                    break;
                }
            }
        }
        if (should_trim (m, m->topsize))
            sys_trim (m, 0);
        POSTACTION (m);
    }
    return unfreed;
}

/* ----------------------------- user mspaces ---------------------------- */

static mstate init_user_mstate (char * tbase, size_t tsize)
{
    size_t msize = pad_request (sizeof (struct malloc_state));
    mchunkptr mn;
    mchunkptr msp = align_as_chunk (tbase);
    mstate m = (mstate) (chunk2mem (msp));
    memset (m, 0, msize);
    (void)INITIAL_LOCK (&m->mutex);
    msp->head   = (msize | INUSE_BITS);
    m->seg.base = m->least_addr = tbase;
    m->seg.size = m->footprint = m->max_footprint = tsize;
    m->magic          = mparams.magic;
    m->release_checks = MAX_RELEASE_CHECK_RATE;
    m->mflags         = mparams.default_mflags;
    m->extp           = 0;
    m->exts = 0;
    disable_contiguous (m);
    init_bins (m);
    mn = next_chunk (mem2chunk (m));
    init_top (m, mn, (size_t) ((tbase + tsize) - (char *)mn) - TOP_FOOT_SIZE);
    check_top_chunk (m, m->top);
    return m;
}

mspace create_mspace (size_t capacity, int locked)
{
    mstate m = 0;
    size_t msize;
    ensure_initialization ();
    msize = pad_request (sizeof (struct malloc_state));
    if (capacity < (size_t) - (msize + TOP_FOOT_SIZE + mparams.page_size))
    {
        size_t rs = ((capacity == 0) ? mparams.granularity
                                     : (capacity + TOP_FOOT_SIZE + msize));
        size_t tsize = granularity_align (rs);
        char * tbase = (char *)(CALL_MMAP (tsize));
        if (tbase != CMFAIL)
        {
            m             = init_user_mstate (tbase, tsize);
            m->seg.sflags = USE_MMAP_BIT;
            set_lock (m, locked);
        }
    }
    return (mspace)m;
}

mspace create_mspace_with_base (void * base, size_t capacity, int locked)
{
    mstate m = 0;
    size_t msize;
    ensure_initialization ();
    msize = pad_request (sizeof (struct malloc_state));
    if (capacity > msize + TOP_FOOT_SIZE &&
        capacity < (size_t) - (msize + TOP_FOOT_SIZE + mparams.page_size))
    {
        m             = init_user_mstate ((char *)base, capacity);
        m->seg.sflags = EXTERN_BIT;
        set_lock (m, locked);
    }
    return (mspace)m;
}

int mspace_track_large_chunks (mspace msp, int enable)
{
    int ret   = 0;
    mstate ms = (mstate)msp;
    if (!PREACTION (ms))
    {
        if (!use_mmap (ms))
        {
            ret = 1;
        }
        if (!enable)
        {
            enable_mmap (ms);
        }
        else
        {
            disable_mmap (ms);
        }
        POSTACTION (ms);
    }
    return ret;
}

size_t destroy_mspace (mspace msp)
{
    size_t freed = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        msegmentptr sp = &ms->seg;
        (void)DESTROY_LOCK (&ms->mutex); /* destroy before unmapped */
        while (sp != 0)
        {
            char * base = sp->base;
            size_t size = sp->size;
            flag_t flag = sp->sflags;
            (void)base; /* placate people compiling -Wunused-variable */
            sp = sp->next;
            if ((flag & USE_MMAP_BIT) && !(flag & EXTERN_BIT) &&
                CALL_MUNMAP (base, size) == 0)
                freed += size;
        }
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return freed;
}

/*
  mspace versions of routines are near-clones of the global
  versions. This is not so nice but better than the alternatives.
*/

void * mspace_malloc (mspace msp, size_t bytes)
{
    mstate ms = (mstate)msp;
    if (!ok_magic (ms))
    {
        USAGE_ERROR_ACTION (ms, ms);
        return 0;
    }
    if (!PREACTION (ms))
    {
        void * mem;
        size_t nb;
        if (bytes <= MAX_SMALL_REQUEST)
        {
            bindex_t idx;
            binmap_t smallbits;
            nb        = (bytes < MIN_REQUEST) ? MIN_CHUNK_SIZE : pad_request (bytes);
            idx       = small_index (nb);
            smallbits = ms->smallmap >> idx;

            if ((smallbits & 0x3U) != 0)
            { /* Remainderless fit to a smallbin. */
                mchunkptr b, p;
                idx += ~smallbits & 1; /* Uses next bin if idx empty */
                b = smallbin_at (ms, idx);
                p = b->fd;
                assert (chunksize (p) == small_index2size (idx));
                unlink_first_small_chunk (ms, b, p, idx);
                set_inuse_and_pinuse (ms, p, small_index2size (idx));
                mem = chunk2mem (p);
                check_malloced_chunk (ms, mem, nb);
                goto postaction;
            }

            else if (nb > ms->dvsize)
            {
                if (smallbits != 0)
                { /* Use chunk in next nonempty smallbin */
                    mchunkptr b, p, r;
                    size_t rsize;
                    bindex_t i;
                    binmap_t leftbits =
                        (smallbits << idx) & left_bits (idx2bit (idx));
                    binmap_t leastbit = least_bit (leftbits);
                    compute_bit2idx (leastbit, i);
                    b = smallbin_at (ms, i);
                    p = b->fd;
                    assert (chunksize (p) == small_index2size (i));
                    unlink_first_small_chunk (ms, b, p, i);
                    rsize = small_index2size (i) - nb;
                    /* Fit here cannot be remainderless if 4byte sizes */
                    if (SIZE_T_SIZE != 4 && rsize < MIN_CHUNK_SIZE)
                        set_inuse_and_pinuse (ms, p, small_index2size (i));
                    else
                    {
                        set_size_and_pinuse_of_inuse_chunk (ms, p, nb);
                        r = chunk_plus_offset (p, nb);
                        set_size_and_pinuse_of_free_chunk (r, rsize);
                        replace_dv (ms, r, rsize);
                    }
                    mem = chunk2mem (p);
                    check_malloced_chunk (ms, mem, nb);
                    goto postaction;
                }

                else if (ms->treemap != 0 &&
                         (mem = tmalloc_small (ms, nb)) != 0)
                {
                    check_malloced_chunk (ms, mem, nb);
                    goto postaction;
                }
            }
        }
        else if (bytes >= MAX_REQUEST)
            nb = MAX_SIZE_T; /* Too big to allocate. Force failure (in sys
                                alloc) */
        else
        {
            nb = pad_request (bytes);
            if (ms->treemap != 0 && (mem = tmalloc_large (ms, nb)) != 0)
            {
                check_malloced_chunk (ms, mem, nb);
                goto postaction;
            }
        }

        if (nb <= ms->dvsize)
        {
            size_t rsize = ms->dvsize - nb;
            mchunkptr p = ms->dv;
            if (rsize >= MIN_CHUNK_SIZE)
            { /* split dv */
                mchunkptr r = ms->dv = chunk_plus_offset (p, nb);
                ms->dvsize = rsize;
                set_size_and_pinuse_of_free_chunk (r, rsize);
                set_size_and_pinuse_of_inuse_chunk (ms, p, nb);
            }
            else
            { /* exhaust dv */
                size_t dvs = ms->dvsize;
                ms->dvsize = 0;
                ms->dv = 0;
                set_inuse_and_pinuse (ms, p, dvs);
            }
            mem = chunk2mem (p);
            check_malloced_chunk (ms, mem, nb);
            goto postaction;
        }

        else if (nb < ms->topsize)
        { /* Split top */
            size_t rsize = ms->topsize -= nb;
            mchunkptr p  = ms->top;
            mchunkptr r = ms->top = chunk_plus_offset (p, nb);
            r->head = rsize | PINUSE_BIT;
            set_size_and_pinuse_of_inuse_chunk (ms, p, nb);
            mem = chunk2mem (p);
            check_top_chunk (ms, ms->top);
            check_malloced_chunk (ms, mem, nb);
            goto postaction;
        }

        mem = sys_alloc (ms, nb);

    postaction:
        POSTACTION (ms);
        return mem;
    }

    return 0;
}

void mspace_free (mspace msp, void * mem)
{
    if (mem != 0)
    {
        mchunkptr p = mem2chunk (mem);
        mstate fm = (mstate)msp;
        if (!ok_magic (fm))
        {
            USAGE_ERROR_ACTION (fm, p);
            return;
        }
        if (!PREACTION (fm))
        {
            check_inuse_chunk (fm, p);
            if (RTCHECK (ok_address (fm, p) && ok_inuse (p)))
            {
                size_t psize   = chunksize (p);
                mchunkptr next = chunk_plus_offset (p, psize);
                if (!pinuse (p))
                {
                    size_t prevsize = p->prev_foot;
                    if (is_mmapped (p))
                    {
                        psize += prevsize + MMAP_FOOT_PAD;
                        if (CALL_MUNMAP ((char *)p - prevsize, psize) == 0)
                            fm->footprint -= psize;
                        goto postaction;
                    }
                    else
                    {
                        mchunkptr prev = chunk_minus_offset (p, prevsize);
                        psize += prevsize;
                        p = prev;
                        if (RTCHECK (ok_address (fm, prev)))
                        { /* consolidate backward */
                            if (p != fm->dv)
                            {
                                unlink_chunk (fm, p, prevsize);
                            }
                            else if ((next->head & INUSE_BITS) == INUSE_BITS)
                            {
                                fm->dvsize = psize;
                                set_free_with_pinuse (p, psize, next);
                                goto postaction;
                            }
                        }
                        else
                            goto erroraction;
                    }
                }

                if (RTCHECK (ok_next (p, next) && ok_pinuse (next)))
                {
                    if (!cinuse (next))
                    { /* consolidate forward */
                        if (next == fm->top)
                        {
                            size_t tsize = fm->topsize += psize;
                            fm->top      = p;
                            p->head = tsize | PINUSE_BIT;
                            if (p == fm->dv)
                            {
                                fm->dv     = 0;
                                fm->dvsize = 0;
                            }
                            if (should_trim (fm, tsize))
                                sys_trim (fm, 0);
                            goto postaction;
                        }
                        else if (next == fm->dv)
                        {
                            size_t dsize = fm->dvsize += psize;
                            fm->dv = p;
                            set_size_and_pinuse_of_free_chunk (p, dsize);
                            goto postaction;
                        }
                        else
                        {
                            size_t nsize = chunksize (next);
                            psize += nsize;
                            unlink_chunk (fm, next, nsize);
                            set_size_and_pinuse_of_free_chunk (p, psize);
                            if (p == fm->dv)
                            {
                                fm->dvsize = psize;
                                goto postaction;
                            }
                        }
                    }
                    else
                        set_free_with_pinuse (p, psize, next);

                    if (is_small (psize))
                    {
                        insert_small_chunk (fm, p, psize);
                        check_free_chunk (fm, p);
                    }
                    else
                    {
                        tchunkptr tp = (tchunkptr)p;
                        insert_large_chunk (fm, tp, psize);
                        check_free_chunk (fm, p);
                        if (--fm->release_checks == 0)
                            release_unused_segments (fm);
                    }
                    goto postaction;
                }
            }
        erroraction:
            USAGE_ERROR_ACTION (fm, p);
        postaction:
            POSTACTION (fm);
        }
    }
}

void * mspace_calloc (mspace msp, size_t n_elements, size_t elem_size)
{
    void * mem;
    size_t req = 0;
    mstate ms = (mstate)msp;
    if (!ok_magic (ms))
    {
        USAGE_ERROR_ACTION (ms, ms);
        return 0;
    }
    if (n_elements != 0)
    {
        req = n_elements * elem_size;
        if (((n_elements | elem_size) & ~(size_t)0xffff) &&
            (req / n_elements != elem_size))
            req = MAX_SIZE_T; /* force downstream failure on overflow */
    }
    mem = internal_malloc (ms, req);
    if (mem != 0 && calloc_must_clear (mem2chunk (mem)))
        memset (mem, 0, req);
    return mem;
}

void * mspace_realloc (mspace msp, void * oldmem, size_t bytes)
{
    void * mem = 0;
    if (oldmem == 0)
    {
        mem = mspace_malloc (msp, bytes);
    }
    else if (bytes >= MAX_REQUEST)
    {
        MALLOC_FAILURE_ACTION;
    }
#ifdef REALLOC_ZERO_BYTES_FREES
    else if (bytes == 0)
    {
        mspace_free (msp, oldmem);
    }
#endif /* REALLOC_ZERO_BYTES_FREES */
    else
    {
        size_t nb      = request2size (bytes);
        mchunkptr oldp = mem2chunk (oldmem);
        mstate m = (mstate)msp;
        if (!PREACTION (m))
        {
            mchunkptr newp = try_realloc_chunk (m, oldp, nb, 1);
            POSTACTION (m);
            if (newp != 0)
            {
                check_inuse_chunk (m, newp);
                mem = chunk2mem (newp);
            }
            else
            {
                mem = mspace_malloc (m, bytes);
                if (mem != 0)
                {
                    size_t oc = chunksize (oldp) - overhead_for (oldp);
                    memcpy (mem, oldmem, (oc < bytes) ? oc : bytes);
                    mspace_free (m, oldmem);
                }
            }
        }
    }
    return mem;
}

void * mspace_realloc_in_place (mspace msp, void * oldmem, size_t bytes)
{
    void * mem = 0;
    if (oldmem != 0)
    {
        if (bytes >= MAX_REQUEST)
        {
            MALLOC_FAILURE_ACTION;
        }
        else
        {
            size_t nb      = request2size (bytes);
            mchunkptr oldp = mem2chunk (oldmem);
            mstate m = (mstate)msp;
            if (!PREACTION (m))
            {
                mchunkptr newp = try_realloc_chunk (m, oldp, nb, 0);
                POSTACTION (m);
                if (newp == oldp)
                {
                    check_inuse_chunk (m, newp);
                    mem = oldmem;
                }
            }
        }
    }
    return mem;
}

void * mspace_memalign (mspace msp, size_t alignment, size_t bytes)
{
    mstate ms = (mstate)msp;
    if (!ok_magic (ms))
    {
        USAGE_ERROR_ACTION (ms, ms);
        return 0;
    }
    if (alignment <= MALLOC_ALIGNMENT)
        return mspace_malloc (msp, bytes);
    return internal_memalign (ms, alignment, bytes);
}

size_t mspace_bulk_free (mspace msp, void * array[], size_t nelem)
{
    return internal_bulk_free ((mstate)msp, array, nelem);
}

#if MALLOC_INSPECT_ALL
void mspace_inspect_all (mspace msp, void (*handler) (void * start, void * end,
                                                      size_t used_bytes,
                                                      void * callback_arg),
                         void * arg)
{
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        if (!PREACTION (ms))
        {
            internal_inspect_all (ms, handler, arg);
            POSTACTION (ms);
        }
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
}
#endif /* MALLOC_INSPECT_ALL */

int mspace_trim (mspace msp, size_t pad)
{
    int result = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        if (!PREACTION (ms))
        {
            result = sys_trim (ms, pad);
            POSTACTION (ms);
        }
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return result;
}

#if !NO_MALLOC_STATS
void mspace_malloc_stats (mspace msp)
{
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        internal_malloc_stats (ms);
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
}
#endif /* NO_MALLOC_STATS */

size_t mspace_footprint (mspace msp)
{
    size_t result = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        result = ms->footprint;
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return result;
}

size_t mspace_max_footprint (mspace msp)
{
    size_t result = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        result = ms->max_footprint;
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return result;
}

size_t mspace_footprint_limit (mspace msp)
{
    size_t result = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        size_t maf = ms->footprint_limit;
        result     = (maf == 0) ? MAX_SIZE_T : maf;
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return result;
}

size_t mspace_set_footprint_limit (mspace msp, size_t bytes)
{
    size_t result = 0;
    mstate ms = (mstate)msp;
    if (ok_magic (ms))
    {
        if (bytes == 0)
            result = granularity_align (1); /* Use minimal size */
        else if (bytes == MAX_SIZE_T)
            result = 0; /* disable */
        else
            result          = granularity_align (bytes);
        ms->footprint_limit = result;
    }
    else
    {
        USAGE_ERROR_ACTION (ms, ms);
    }
    return result;
}

size_t mspace_usable_size (const void * mem)
{
    if (mem != 0)
    {
        mchunkptr p = mem2chunk (mem);
        if (is_inuse (p))
            return chunksize (p) - overhead_for (p);
    }
    return 0;
}

int mspace_mallopt (int param_number, int value)
{
    return change_mparam (param_number, value);
}

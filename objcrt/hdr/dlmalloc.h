/*
  This is a version (aka dlmalloc) of malloc/free/realloc written by
  Doug Lea and released to the public domain, as explained at
  http://creativecommons.org/publicdomain/zero/1.0/ Send questions,
  comments, complaints, performance data, etc to dl@cs.oswego.edu
*/

/* Version identifier to allow people to support multiple versions */
#ifndef DLMALLOC_VERSION
#define DLMALLOC_VERSION 20806
#endif /* DLMALLOC_VERSION */

#ifndef DLMALLOC_EXPORT
#define DLMALLOC_EXPORT extern
#endif

#ifndef WIN32
#ifdef _WIN32
#define WIN32 1
#endif /* _WIN32 */
#ifdef _WIN32_WCE
#define LACKS_FCNTL_H
#define WIN32 1
#endif /* _WIN32_WCE */
#endif /* WIN32 */
#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tchar.h>
#define HAVE_MMAP 1
#define HAVE_MORECORE 0
#define LACKS_UNISTD_H
#define LACKS_SYS_PARAM_H
#define LACKS_SYS_MMAN_H
#define LACKS_STRING_H
#define LACKS_STRINGS_H
#define LACKS_SYS_TYPES_H
#define LACKS_ERRNO_H
#define LACKS_SCHED_H
#ifndef MALLOC_FAILURE_ACTION
#define MALLOC_FAILURE_ACTION
#endif /* MALLOC_FAILURE_ACTION */
#ifndef MMAP_CLEARS
#ifdef _WIN32_WCE /* WINCE reportedly does not clear */
#define MMAP_CLEARS 0
#else
#define MMAP_CLEARS 1
#endif /* _WIN32_WCE */
#endif /*MMAP_CLEARS */
#endif /* WIN32 */

#if defined(DARWIN) || defined(_DARWIN)
/* Mac OSX docs advise not to use sbrk; it seems better to use mmap */
#ifndef HAVE_MORECORE
#define HAVE_MORECORE 0
#define HAVE_MMAP 1
/* OSX allocators provide 16 byte alignment */
#ifndef MALLOC_ALIGNMENT
#define MALLOC_ALIGNMENT ((size_t)16U)
#endif
#endif /* HAVE_MORECORE */
#endif /* DARWIN */

#ifndef LACKS_SYS_TYPES_H
#include <sys/types.h> /* For size_t */
#endif                 /* LACKS_SYS_TYPES_H */

/* The maximum possible size_t value has all bits set */
#define MAX_SIZE_T (~(size_t)0)

#if ((defined(__GNUC__) &&                                                     \
      ((__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1)) ||             \
       defined(__i386__) || defined(__x86_64__))) ||                           \
     (defined(_MSC_VER) && _MSC_VER >= 1310))
#ifndef USE_SPIN_LOCKS
#define USE_SPIN_LOCKS 1
#endif /* USE_SPIN_LOCKS */
#elif USE_SPIN_LOCKS
#error "USE_SPIN_LOCKS defined without implementation"
#endif /* ... locks available... */

#ifndef MALLOC_ALIGNMENT
#define MALLOC_ALIGNMENT ((size_t) (2 * sizeof (void *)))
#endif /* MALLOC_ALIGNMENT */
#ifndef ABORT
#define ABORT abort ()
#endif /* ABORT */
#ifndef ABORT_ON_ASSERT_FAILURE
#define ABORT_ON_ASSERT_FAILURE 1
#endif /* ABORT_ON_ASSERT_FAILURE */

#ifndef INSECURE
#define INSECURE 0
#endif /* INSECURE */
#ifndef MALLOC_INSPECT_ALL
#define MALLOC_INSPECT_ALL 0
#endif /* MALLOC_INSPECT_ALL */
#ifndef HAVE_MMAP
#define HAVE_MMAP 1
#endif /* HAVE_MMAP */
#ifndef MMAP_CLEARS
#define MMAP_CLEARS 1
#endif /* MMAP_CLEARS */
#ifndef MALLOC_FAILURE_ACTION
#define MALLOC_FAILURE_ACTION errno = ENOMEM;
#endif /* MALLOC_FAILURE_ACTION */
#ifndef HAVE_MORECORE
#define HAVE_MORECORE 0
#endif /* HAVE_MORECORE */
#if !HAVE_MORECORE
#define MORECORE_CONTIGUOUS 0
#else /* !HAVE_MORECORE */
#define MORECORE_DEFAULT sbrk
#ifndef MORECORE_CONTIGUOUS
#define MORECORE_CONTIGUOUS 1
#endif /* MORECORE_CONTIGUOUS */
#endif /* HAVE_MORECORE */
#ifndef DEFAULT_GRANULARITY
#if (MORECORE_CONTIGUOUS || defined(WIN32))
#define DEFAULT_GRANULARITY (0) /* 0 means to compute in init_mparams */
#else                           /* MORECORE_CONTIGUOUS */
#define DEFAULT_GRANULARITY ((size_t)64U * (size_t)1024U)
#endif /* MORECORE_CONTIGUOUS */
#endif /* DEFAULT_GRANULARITY */
#ifndef DEFAULT_TRIM_THRESHOLD
#ifndef MORECORE_CANNOT_TRIM
#define DEFAULT_TRIM_THRESHOLD ((size_t)2U * (size_t)1024U * (size_t)1024U)
#else /* MORECORE_CANNOT_TRIM */
#define DEFAULT_TRIM_THRESHOLD MAX_SIZE_T
#endif /* MORECORE_CANNOT_TRIM */
#endif /* DEFAULT_TRIM_THRESHOLD */
#ifndef DEFAULT_MMAP_THRESHOLD
#if HAVE_MMAP
#define DEFAULT_MMAP_THRESHOLD ((size_t)256U * (size_t)1024U)
#else /* HAVE_MMAP */
#define DEFAULT_MMAP_THRESHOLD MAX_SIZE_T
#endif /* HAVE_MMAP */
#endif /* DEFAULT_MMAP_THRESHOLD */
#ifndef MAX_RELEASE_CHECK_RATE
#if HAVE_MMAP
#define MAX_RELEASE_CHECK_RATE 4095
#else
#define MAX_RELEASE_CHECK_RATE MAX_SIZE_T
#endif /* HAVE_MMAP */
#endif /* MAX_RELEASE_CHECK_RATE */
#ifndef USE_BUILTIN_FFS
#define USE_BUILTIN_FFS 0
#endif /* USE_BUILTIN_FFS */
#ifndef MALLINFO_FIELD_TYPE
#define MALLINFO_FIELD_TYPE size_t
#endif /* MALLINFO_FIELD_TYPE */
#ifndef NO_MALLOC_STATS
#define NO_MALLOC_STATS 0
#endif /* NO_MALLOC_STATS */
#ifndef NO_SEGMENT_TRAVERSAL
#define NO_SEGMENT_TRAVERSAL 0
#endif /* NO_SEGMENT_TRAVERSAL */

/*
  mallopt tuning options.  SVID/XPG defines four standard parameter
  numbers for mallopt, normally defined in malloc.h.  None of these
  are used in this malloc, so setting them has no effect. But this
  malloc does support the following options.
*/

#define M_TRIM_THRESHOLD (-1)
#define M_GRANULARITY (-2)
#define M_MMAP_THRESHOLD (-3)

/* ------------------------ Mallinfo declarations ------------------------ */

/*
  Try to persuade compilers to inline. The most critical functions for
  inlining are defined as macros, so these aren't used for them.
*/

#ifndef FORCEINLINE
#if defined(__GNUC__)
#define FORCEINLINE __inline __attribute__ ((always_inline))
#elif defined(_MSC_VER)
#define FORCEINLINE __forceinline
#endif
#endif
#ifndef NOINLINE
#if defined(__GNUC__)
#define NOINLINE __attribute__ ((noinline))
#elif defined(_MSC_VER)
#define NOINLINE __declspec(noinline)
#else
#define NOINLINE
#endif
#endif

#ifdef __cplusplus
extern "C" {
#ifndef FORCEINLINE
#define FORCEINLINE inline
#endif
#endif /* __cplusplus */
#ifndef FORCEINLINE
#define FORCEINLINE
#endif

/*
    mspace is an opaque type representing an independent
    region of space that supports mspace_malloc, etc.
*/
typedef void * mspace;

/*
    create_mspace creates and returns a new independent space with the
    given initial capacity, or, if 0, the default granularity size.
*/
DLMALLOC_EXPORT mspace create_mspace (size_t capacity, int locked);

/*
    destroy_mspace destroys the given space, and attempts to return all
    of its memory back to the system, returning the total number of
    bytes freed.
*/
DLMALLOC_EXPORT size_t destroy_mspace (mspace msp);

/*
    create_mspace_with_base uses the memory supplied as the initial base
    of a new mspace. Part (less than 128*sizeof(size_t) bytes) of this
    space is used for bookkeeping, so the capacity must be at least this
    large. (Otherwise 0 is returned.) When this initial space is
    exhausted, additional memory will be obtained from the system.
    Destroying this space will deallocate all additionally allocated
    space (if possible) but not the initial base.
*/
DLMALLOC_EXPORT mspace create_mspace_with_base (void * base, size_t capacity,
                                                int locked);

/*
    mspace_track_large_chunks controls whether requests for large chunks
    are allocated in their own untracked mmapped regions, separate from
    others in this mspace. By default large chunks are not tracked,
    which reduces fragmentation. However, such chunks are not
    necessarily released to the system upon destroy_mspace.  Enabling
    tracking by setting to true may increase fragmentation, but avoids
    leakage when relying on destroy_mspace to release all memory
    allocated using this space.  The function returns the previous
    setting.
*/
DLMALLOC_EXPORT int mspace_track_large_chunks (mspace msp, int enable);

/*
    mspace_malloc behaves as malloc, but operates within
    the given space.
*/
DLMALLOC_EXPORT void * mspace_malloc (mspace msp, size_t bytes);

/*
    mspace_free behaves as free, but operates within
    the given space.
*/
DLMALLOC_EXPORT void mspace_free (mspace msp, void * mem);

/*
    mspace_realloc behaves as realloc, but operates within
    the given space.
*/
DLMALLOC_EXPORT void * mspace_realloc (mspace msp, void * mem, size_t newsize);

/*
    mspace_calloc behaves as calloc, but operates within
    the given space.
*/
DLMALLOC_EXPORT void * mspace_calloc (mspace msp, size_t n_elements,
                                      size_t elem_size);

/*
    mspace_memalign behaves as memalign, but operates within
    the given space.
*/
DLMALLOC_EXPORT void * mspace_memalign (mspace msp, size_t alignment,
                                        size_t bytes);

/*
    mspace_footprint() returns the number of bytes obtained from the
    system for this space.
*/
DLMALLOC_EXPORT size_t mspace_footprint (mspace msp);

/*
    mspace_max_footprint() returns the peak number of bytes obtained from the
    system for this space.
*/
DLMALLOC_EXPORT size_t mspace_max_footprint (mspace msp);

/*
    malloc_usable_size(void* p) behaves the same as malloc_usable_size;
*/
DLMALLOC_EXPORT size_t mspace_usable_size (const void * mem);

/*
    mspace_malloc_stats behaves as malloc_stats, but reports
    properties of the given space.
*/
DLMALLOC_EXPORT void mspace_malloc_stats (mspace msp);

/*
    mspace_trim behaves as malloc_trim, but
    operates within the given space.
*/
DLMALLOC_EXPORT int mspace_trim (mspace msp, size_t pad);

#ifdef __cplusplus
} /* end of extern "C" */
#endif /* __cplusplus */
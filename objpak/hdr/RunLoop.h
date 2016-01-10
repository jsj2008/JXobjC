/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <sys/select.h>

#import "IODevice.h"
#import "SortCltn.h"
#import "Stack.h"
#import "Set.h"

@class Date;
@class Pipe;
@class RunLoopDescriptor;
@class Timer;

/*!
 * @abstract Run Loop
 * @discussion Run loop for your program. Allows the multiplexing of timers,
 * sockets, and other events, and provides the ability to perform blocks or
 * selectors after an iteration, waking up if asleep to perform these.
 * @indexgroup Run Loop
 */
@interface RunLoop : Object
{
    /* In fact, all of these collections are actually AtomicProxies;
     * this is because the RunLoop may be manipulated from another thread.
     * The AtomicProxy is an example of the Advanced Seperation of Cocncerns,
     * or the Aspect-Oriented Programming. It appears to be a regular SortCltn,
     * Stack, or Set, but in fact, it is proxied through with mutex locking on
     * the call. It transparently segregates a crosscutting concern away. */
    SortCltn * _timers;
    Stack * _performs;
    Set * _eventSources; /* The entries are RunLoopDescriptors. */

    Pipe * _comm;
    BOOL _seltabNeedsRebuild;
    fd_set _reads, _writes, _excepts;
    SocketDescriptor highFd;
} :
{
    id mainRunLoop;
}

/*! Whether the Run Loop is currently running. */
@property BOOL running;

+ (RunLoop *)mainRunLoop;
+ (RunLoop *)currentRunLoop;

- (BOOL)runBeforeDate:(Date *)date;

- associateDescriptor:(RunLoopDescriptor *)desc;
- associateTimer:(Timer *)timer;

- performSelector:(SEL)sel target:targ argument:arg;
- performBlock:blk argument:arg;
- (void)cancelPerformSelector:(SEL)sel target:targ argument:arg;
- (void)cancelPerformSelectorsWithTarget:targ;
- (void)cancelPerformBlock:blk argument:arg;

/* private */
- rebuildSeltab;

@end

/* Partially abstract class describing a task that a run loop may perform.
 * Used unmodified for queued performers; adapted for timers and other
 * events. */
@interface RunLoopExecutor : Object
{
    /* Perform a selector on a target: */
    SEL selector;
    id target;

    /* or, alternatively, a block: */
    id block;

    /* And an argument passed to each. */
    id argument;
}

+ newWithSelector:(SEL)sel target:targ argument:arg;
+ newWithBlock:blk argument:arg;

- initWithSelector:(SEL)sel target:targ argument:arg;
- initWithBlock:blk argument:arg;

- (BOOL)matchesSelector:(SEL)sel target:targ argument:arg;
- (BOOL)matchesTarget:targ;
- (BOOL)matchesBlock:blk argument:arg;
- (BOOL)matchesBlock:blk;

/* Without prejudicing its typical schedule, run the executor once. */
- (void)fire;

@end

typedef enum FdEvSourceType_e
{
    FDEV_READ   = 1,
    FDEV_WRITE  = 2,
    FDEV_EXCEPT = 4,
} FdEvSourceType_t;

@interface RunLoopDescriptor : RunLoopExecutor
{
    id iod;
}

@property volatile BOOL valid;
@property enum FdEvSourceType_e descriptorEventType;
@property /* (readonly) */ SocketDescriptor readFd, writeFd;
@property /* (readonly) */ BOOL readExc, writeExc;

- setIOD:aniod eventTypes:(FdEvSourceType_t)types;

- descriptorReadyForRead:(SocketDescriptor)fd;
- descriptorReadyForWrite:(SocketDescriptor)fd;
- descriptorException:(SocketDescriptor)fd;

@end
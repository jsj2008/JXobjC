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

@interface RunLoop : Object
{
    SortCltn * _timers;
    Stack * _performs;   /* In fact, this is an AtomicProxy to a Stack. */
    Set * _eventSources; /* The entries are RunLoopDescriptors. */
    Pipe * _comm;

    BOOL _seltabNeedsRebuild;
    fd_set _reads, _writes, _excepts;
    SocketDescriptor highFd;
} :
{
    id mainRunLoop;
}

@property BOOL running;

+ (RunLoop *)mainRunLoop;
+ (RunLoop *)currentRunLoop;

- (BOOL)runBeforeDate:(Date *)date;

- associateDescriptor:(RunLoopDescriptor *)desc;
- associateTimer:(Timer *)timer;

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
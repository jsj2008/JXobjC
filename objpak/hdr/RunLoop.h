/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "OrdCltn.h"
#import "Stack.h"

@interface RunLoop : Object
{
    OrdCltn * _timers;
    Stack * _performs;
    OrdCltn * _eventSources;
} : 
{
    id mainRunLoop;
}

@property BOOL running;

+ (RunLoop *)mainRunLoop;
+ (RunLoop *)currentRunLoop;

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

    /* Used in the DescriptorEventSource specialisation. */
    volatile id IODevice;
}

@property enum FdEvSourceType_e fdEvSourceType;

+ newWithSelector:(SEL)sel target:targ argument:arg;
+ newWithBlock:blk argument:arg;

- initWithSelector:(SEL)sel target:targ argument:arg;
- initWithBlock:blk argument:arg;

/* Without prejudicing its typical schedule, run the executor once. */
- (void)fire;

@end

typedef enum FdEvSourceType_e
{
    FDEVSOURCE_INPUT  = 1,
    FDEVSOURCE_OUTPUT = 2,
    FDEVSOURCE_EXCEPT = 4,
} FdEvSourceType_t;

@interface RunLoopExecutor (DescriptorEventSource)

@end
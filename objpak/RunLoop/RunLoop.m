/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Block.h"
#import "Date.h"
#import "Pipe.h"
#import "RunLoop.h"
#import "Thread.h"

@implementation RunLoop

+ initialize
{
    [super initialize];
    mainRunLoop = [[self alloc] init];
    [[Thread mainThread] setRunLoop:mainRunLoop];
    return self;
}

- init
{
    [super init];
    _timers       = [SortCltn new];
    _performs     = [Stack new];
    _eventSources = [Set new];
    return self;
}

- ARC_dealloc
{
    _timers       = nil;
    _performs     = nil;
    _eventSources = nil;
    _comm         = nil;
    return [super ARC_dealloc];
}

+ (RunLoop *)mainRunLoop { return [[Thread mainThread] runLoop]; }
+ (RunLoop *)currentRunLoop { return [[Thread currentThread] runLoop]; }

- associateDescriptor:(RunLoopDescriptor *)desc
{
    [_eventSources add:desc];
    return self;
}

- associateTimer:(Timer *)timer
{
    [_timers add:timer];
    return self;
}

- (BOOL)runBeforeDate:(Date *)limitDate
{
    BOOL inputSourceEvent = NO;

    while (!inputSourceEvent)
    {
        struct timeval tv;
        TimeInterval limitSecs;
        unsigned depth;

        if ((depth = [_performs depth]))
            while (depth--)
                [[_performs pop] fire];

        [self rebuildSeltab];

        limitSecs = [limitDate timeIntervalSinceNow];
        [_timers
            do:
            { :each | TimeInterval c;
                if ((c = [[each fireDate] timeIntervalSinceNow]) < limitSecs)
                    limitSecs = c;
            }];

        tv = JXtimevalFromTimeInterval (limitSecs);
        select (highFd, &_reads, &_writes, &_excepts, &tv);
    }
    return YES;
}

- rebuildSeltab
{
    FD_ZERO (&_reads);
    FD_ZERO (&_writes);
    FD_ZERO (&_excepts);
    highFd = 0;

    FD_SET ([_comm readDescriptor], &_reads);
    [_eventSources do:
                   { :each | SocketDescriptor r, w;
                       r = [each readFd] != -1 ? [each readFd] : 0;
                       w = [each writeFd] != 1 ? [each writeFd] : 0;
                       if (r)
                           FD_SET (r, &_reads);
                       if (w)
                           FD_SET (w, &_writes);
                       if (r && [each readExc])
                           FD_SET (r, &_excepts);
                       if (w && [each writeExc])
                           FD_SET (w, &_excepts);
                       if (r > highFd)
                           highFd = r;
                       if (w > highFd)
                           highFd = w;
                   }];

    return self;
}

@end
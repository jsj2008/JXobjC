/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "AtomicProxy.h"
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
    _timers       = [AtomicProxy atomicProxyWithTarget:[SortCltn new]];
    _performs     = [AtomicProxy atomicProxyWithTarget:[Stack new]];
    _eventSources = [AtomicProxy atomicProxyWithTarget:[Set new]];
    _comm         = [AtomicProxy atomicProxyWithTarget:[Pipe new]];
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

+ (RunLoop)mainRunLoop { return [[Thread mainThread] runLoop]; }
+ (RunLoop)currentRunLoop { return [[Thread currentThread] runLoop]; }

- associateDescriptor:(RunLoopDescriptor)desc
{
    [_eventSources add:desc];
    return self;
}

- associateTimer:(Timer)timer
{
    [_timers add:timer];
    return self;
}

- (BOOL)runBeforeDate:(Date)limitDate
{
    BOOL inputSourceEvent = NO;

    while (!inputSourceEvent)
    {
        struct timeval tv;
        TimeInterval limitSecs;
        unsigned depth, cur;

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

        for (cur = 0; cur != highFd; cur++)
        {
            BOOL found;

            if (FD_ISSET (cur, &_reads))
                [_eventSources do:
                               { :each |
                          if ([each readDescriptor] == cur)
                                   {
                                       [each descriptorReadyForRead:cur];
                                       found            = YES;
                                       inputSourceEvent = YES;
                                   }
                               }
                            until:&found];
            found = NO;

            if (FD_ISSET (cur, &_writes))
                [_eventSources do:
                               { :each |
                          if ([each writeDescriptor] == cur)
                                   {
                                       [each descriptorReadyForWrite:cur];
                                       found            = YES;
                                       inputSourceEvent = YES;
                                   }
                               }
                            until:&found];

            if (FD_ISSET (cur, &_excepts))
                [_eventSources do:
                               { :each |
                          if ([each readDescriptor] == cur || [each writeDescriptor] == cur)
                                   {
                                       [each descriptorException:cur];
                                       found            = YES;
                                       inputSourceEvent = YES;
                                   }
                               }
                            until:&found];
        }

        [_timers do:
                 { :each |
                if ([[each fireDate] timeIntervalSinceNow] <= 0)
                    [each fire];
                 }];

        if ([limitDate timeIntervalSinceNow] <= 0)
            return YES;
    }
    return YES;
}

- performSelector:(SEL)sel target:targ argument:arg
{
    [_performs
        push:[RunLoopExecutor newWithSelector:sel target:targ argument:arg]];
    return self;
}

- performBlock:blk argument:arg
{
    [_performs push:[RunLoopExecutor newWithBlock:blk argument:arg]];
    return self;
}

- (void)cancelPerformSelector:(SEL)sel target:targ argument:arg
{
    id subset;

    subset = [_performs
        select:{ : each | [each matchesSelector:sel target:targ argument:arg]}];
    [_performs removeContentsOf:subset];
}

- (void)cancelPerformSelectorsWithTarget:targ
{
    id subset;

    subset = [_performs select:{ : each | [each matchesTarget:targ]}];
    [_performs removeContentsOf:subset];
}

- (void)cancelPerformBlock:blk argument:arg
{
    id subset;

    subset =
        [_performs select:{ : each | [each matchesBlock:blk argument:arg]}];
    [_performs removeContentsOf:subset];
}

- (void)cancelPerformBlock:blk
{
    id subset;

    subset = [_performs select:{ : each | [each matchesBlock:blk]}];
    [_performs removeContentsOf:subset];
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

    highFd++;

    return self;
}

@end

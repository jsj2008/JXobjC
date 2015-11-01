/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Block.h"
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
    return [super ARC_dealloc];
}

+ (RunLoop *)mainRunLoop { return [[Thread mainThread] runLoop]; }
+ (RunLoop *)currentRunLoop { return [[Thread currentThread] runLoop]; }

- associateDescriptor:(RunLoopDescriptor *)desc { return self; }

- rebuildSeltab
{
    FD_ZERO (&_reads);
    FD_ZERO (&_writes);
    FD_ZERO (&_excepts);
    highFd = 0;

    FD_SET ([_comm readDescriptor], &_reads);
    [_eventSources do:
                   { :each | SocketDescriptor r, w;
                       r = [each readFd];
                       w = [each writeFd];
                       if (r)
                           FD_SET (r, &_reads);
                       if (w)
                           FD_SET (w, &_writes);
                       if ([each readExc])
                           FD_SET (r, &_excepts);
                       if ([each writeExc])
                           FD_SET (w, &_excepts);
                       if (r > highFd)
                           highFd = r;
                       if (w > highFd)
                           highFd = w;
                   }];

    return self;
}

@end
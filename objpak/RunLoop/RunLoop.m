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

@end
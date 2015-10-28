/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Block.h"
#import "RunLoop.h"
#import "Thread.h"

@interface RunLoopExecutor : Object
{
    SEL selector;
    id target;
    id argument;
}

+ newWithSelector:(SEL)sel target:targ argument:arg;
- initWithSelector:(SEL)sel target:targ argument:arg;

- (void)execute;

@end

@implementation RunLoopExecutor

- initWithSelector:(SEL)sel target:targ argument:arg
{
    [super init];
    selector = sel;
    target   = targ;
    argument = arg;
    return self;
}

+ newWithSelector:(SEL)sel target:targ argument:arg
{
    return [[self alloc] initWithSelector:sel target:targ argument:arg];
}

- ARC_dealloc
{
    target   = nil;
    argument = nil;
    return [super ARC_dealloc];
}

- (void)execute
{
    [
        {
            [target perform:selector with:argument];
            ;
        } ifError:
          {
        :msg :rcv | printf("Exception in RunLoop executor method.\n");
          }];
}

@end

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

+ (RunLoop *)mainRunLoop { return [[Thread mainThread] runLoop]; }
+ (RunLoop *)currentRunLoop { return [[Thread currentThread] runLoop]; }

@end
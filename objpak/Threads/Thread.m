/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "automgr.h"
#import "Block.h"
#import "Exceptn.h"
#import "Thread.h"
#import "OCString.h"

@implementation Thread

+ initialize
{
    [super initialize];
    pthread_key_create (&currentThread, 0);
    mainThread = [[Thread alloc] _initAsMainThread];
    pthread_setspecific (currentThread, mainThread);
    return self;
}

- _initAsMainThread
{
    [super init];
    isMainThread = YES;
    return self;
}

- init
{
    [super init];
    pthread_attr_init (&_thrd_attr);
    pthread_attr_setdetachstate (&_thrd_attr, PTHREAD_CREATE_DETACHED);
    threadDictionary = [Dictionary new];
    return self;
}

- initWithSelector:(SEL)selector toTarget:target withObject:argument
{
    [self init];
    _selector  = selector;
    _object    = target;
    _parameter = argument;
    return self;
}

+ (void)detachNewThreadSelector:(SEL)sel toTarget:targ withObject:arg
{
    [[[Thread alloc] initWithSelector:sel toTarget:targ withObject:arg] start];
}

- ARC_dealloc
{
    printf ("dealloc\n");
    threadDictionary = nil;
    _return = nil;
    pthread_attr_destroy (&_thrd_attr);
    return [super ARC_dealloc];
}

+ (BOOL)isMainThread { return mainThread == [Thread currentThread]; }
+ (Thread)mainThread { return mainThread; };
+ (Thread)currentThread { return pthread_getspecific (currentThread); }
+ (Dictionary)threadDictionary
{
    return [[self currentThread] threadDictionary];
}

+ (void)_setCurrentThread:(Thread)thrd
{
    pthread_setspecific (currentThread, thrd);
}

static void * _threadStart2 (Thread thread)
{

    [Thread _setCurrentThread:thread];
    [thread setIsExecuting:YES];
    [
        {
            thread._return = [thread main];
        } ifError:
          { :rcv :err | printf("Exception in thread main method!\n");
          }];
    [thread setIsExecuting:NO];
    [thread setIsFinished:YES];
    thread = nil;
    return 0;
}

static void * _threadStart (Thread thread)
{
    /* void * iGetStackBase = (void *)0; */
    return _threadStart2 (thread);
}

- (void)start
{
    short res;
    if (isExecuting)
        [Exception str:"Thread is already running."];
    if (isFinished)
        _return = nil;

    [self setIsCancelled:0];
    [self setIsExecuting:0];
    [self setIsFinished:0];
    res = pthread_create (&_thrd, &_thrd_attr, (void * (*)(void *))_threadStart,
                          idincref (self));
    if (res)
        [Exception signal:"Failed to start thread."];
}

- (void)cancel
{
    if (!isExecuting)
        return;
    else if (isFinished)
        return;
    else if (isCancelled)
        return;
    [self setIsCancelled:YES];
}

- (void)exit
{
    if (!isExecuting)
        return;
    else if (isFinished)
        return;
    else if (isCancelled)
        return;
    pthread_cancel (_thrd);
}

- main
{
    if (_selector && _parameter)
        return [_object perform:_selector with:_parameter];
    else if (_selector)
        return [_object perform:_selector];
    else if (_object && _parameter)
        return [_object value:_parameter];
    else if (_object)
        return [_object value];
    return nil;
}

@end

@implementation Object (Threads)

- (void)performSelectorInBackground:(SEL)selector withObject:object
{
    [Thread detachNewThreadSelector:selector toTarget:self withObject:object];
}

@end

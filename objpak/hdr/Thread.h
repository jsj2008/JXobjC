/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <pthread.h>

#import "Object.h"
#import "Dictionary.h"
#import "RunLoop.h"

@interface Thread : Object
{
    pthread_t _thrd;
    pthread_attr_t _thrd_attr;
    SEL _selector;
    volatile id _object, _parameter;
} :
{
    id mainThread;
    pthread_key_t currentThread;
}

@property id _return;

@property BOOL isMainThread, isCancelled, isExecuting, isFinished;
@property Dictionary * threadDictionary;
@property RunLoop * runLoop;

+ (void)detachNewThreadSelector:(SEL)selector
                       toTarget:target
                     withObject:argument;

+ (BOOL)isMainThread;
+ (Thread *)mainThread;
+ (Thread *)currentThread;
+ (Dictionary *)threadDictionary;

- (void)start;
- (void)cancel;
- (void)exit;
- main;

/* private */
+ initialize;
- _initAsMainThread;
- ARC_dealloc;
@end

@interface Object (Threads)

- (void)performSelectorInBackground:(SEL)selector withObject:object;

@end
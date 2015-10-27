/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <pthread.h>

#import "Object.h"
#import "Dictionary.h"

@interface Thread : Object
{
    pthread_t _thrd;
    pthread_attr_t _thrd_attr;
    SEL _selector;
    volatile id _object, _parameter;
    id _return;
} :
{
    id mainThread;
    pthread_key_t currentThread;
}

@property BOOL isMainThread, isCancelled, isExecuting, isFinished;
@property Dictionary * threadDictionary;

+ initialize;
- _initAsMainThread;
- ARC_dealloc;

+ (Thread *)mainThread;
+ (Thread *)currentThread;
+ (Dictionary *)threadDictionary;

- (void)start;
- (void)cancel;
- (void)exit;
- main;

@end
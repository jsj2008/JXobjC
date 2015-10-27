/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import <Thread.h>

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

+ (Thread *)mainThread { return mainThread; };
+ (Thread *)currentThread { return pthread_getspecific (currentThread); }

@end
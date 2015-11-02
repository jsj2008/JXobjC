/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "AtomicProxy.h"
#import "Message.h"

@implementation AtomicProxy

- initWithTarget:object
{
    [self init];
    _delegate = object;
    return self;
}

+ atomicProxyWithTarget:object
{
    return [[AtomicProxy alloc] initWithTarget:object];
}

- ARC_dealloc
{
    _delegate = nil;
    return [super ARC_dealloc];
}

- doesNotUnderstand:msg
{
    @synchronized (self) { [msg sentTo:_delegate]; }
    return nil;
}

@end
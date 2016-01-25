/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Proxy.h"

/*!
 * @abstract Atomic proxy
 * @discussion Makes atomic any message sends to a specified object: while
 * one is being actioned, others will be required to wait. The AtomicProxy
 * will behave as the proxied object does in most ways, forwarding invisibly
 * any message invocations onwards. This class makes it possible to turn
 * any object into a thread-safe object.
 * @indexgroup Threads
 */
@interface AtomicProxy : Proxy
{
    id _delegate;
}

- ARC_dealloc;

/*! Creates a new atomic proxy with the specified object as its target. */
+ atomicProxyWithTarget:object;

- initWithTarget:object;

@end
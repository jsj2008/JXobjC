/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Proxy.h"

@interface AtomicProxy : Proxy
{
    id _delegate;
}

+ atomicProxyWithTarget:object;
- initWithTarget:object;

@end
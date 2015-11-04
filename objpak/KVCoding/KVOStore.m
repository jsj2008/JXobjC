/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "KVOStore.h"
#import "VolatileReference.h"

@implementation KVOStore

+ (void)addKPObserver:kpo forProperty:propStr ofObject:object
{
    id propDict = [ownerRefToKPObserverDict atKey:object];

    if (!propDict)
    {
        id ref   = [[VolatileReference new] setReferredObject:object];
        propDict = [Dictionary new];
        [ownerRefToKPObserverDict atKey:ref put:propDict];
    }
}

+ (void)addObserver:observer forKeyPath:keyPath ofObject:object {}

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "KVOStore.h"
#import "VolatileReference.h"
#import "Set.h"
#import "KVC.h"

@implementation KVOStore

+ (void)addKPObserver:kpo forProperty:propStr ofObject:object
{
    /*id propDict = [ownerRefToKPObserverDict atKey:object];
    id propKPOSet, tmpKPO;

    if (!propDict)
    {
        id ref   = [[VolatileReference new] setReferredObject:object];
        propDict = [Dictionary new];
        [ownerRefToKPObserverDict atKey:ref put:propDict];
    }

    propKPOSet = [propDict atKey:propStr];
    if (!propKPOSet)
    {
        propKPOSet = [Set new];
        [propDict atKey:propStr put:propKPOSet];
    }

    tmpKPO = [propKPOSet replace:kpo];

#ifndef OBJC_REFCNT
    [tmpKPO free];
#endif*/
}

+ (void)addObserverForKeyPath:keyPath ofObject:object withKPO:KPO
{
    /* The following procedure must be followed for a key of X.Y.Z
     * First, we set up an observer on self.X.
     * Next, on X.Y
     * Finally, on Y.Z
     */
    Pair * resolved = [object resolveKeyPathFirst:[KPO keyPath]];
    printf ("+Add Observer\n");

    if (!resolved.first)
        [self addKPObserver:KPO
                forProperty:[resolved.second copy]
                   ofObject:object];
    else
    {
        id indirector = [object valueForKey:resolved.first];

        /*[self addKPObserver:KPO
                forProperty:[resolved.first copy]
                   ofObject:object];
        [self addObserverForKeyPath:keyPath ofObject:indirector withKPO:KPO];*/
    }

#ifndef OBJC_REFCNT
    [resolved free];
#endif
}

+ (void)addObserver:observer
         forKeyPath:keyPath
           ofObject:object
          withBlock:blk
           userInfo:ui
{
    id kpo = [KPObserver newWithKeyPath:keyPath
                                  block:blk
                               observer:observer
                               userInfo:ui];
    [self addObserverForKeyPath:keyPath ofObject:object withKPO:kpo];
}

+ (void)addObserver:observer
         forKeyPath:keyPath
           ofObject:object
       withSelector:(SEL)sel
           userInfo:ui
{
    id kpo = [KPObserver newWithKeyPath:keyPath
                               selector:sel
                               observer:observer
                               userInfo:ui];
    [self addObserverForKeyPath:keyPath ofObject:object withKPO:kpo];
}

- removeObserver:observer forKeyPath:keyPath ofObject:object {}

@end
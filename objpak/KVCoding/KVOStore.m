/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "KVOStore.h"
#import "VolatileReference.h"
#import "Set.h"
#import "KVC.h"

@implementation KVOStore

+ (void)addKPObserver:kpo
          forProperty:propStr
             ofObject:object
            withIndex:(unsigned int)index
{
    Pair * key = [Pair pairWithVolatileFirst:object second:propStr];
    id value   = [KPObserverRef kpoRefWithKPO:kpo pathIndex:index];

    if (!keyToObservers)
        keyToObservers = [Dictionary new];
    [[keyToObservers atKey:key] ?: [keyToObservers atKey:key put:[Set new]]
        add:value];
}

+ (void)addObserverForKeyPath:keyPath
                     ofObject:object
                      withKPO:KPO
                    fromIndex:(unsigned int)index
{
    /* The following procedure must be followed for a key of X.Y.Z
     * First, we set up an observer on self.X.
     * Next, on X.Y
     * Finally, on Y.Z */
    volatile OrdCltn * components = [KPO keyPathComponents];
    printf ("+Add Observer\n");

    /* Assuming 4 entries:
     * [components size]: 4
     * index for final: 2 (which is the owning object of the terminal property)
     * because W.X.Y.Z decomposes into:
     * 0 W.X
     * 1 X.Y
     * 2 Y.Z */
    if ([components size] - index == 1) /* just-a-key case */
        [self addKPObserver:KPO
                forProperty:[components at:index]
                   ofObject:object
                  withIndex:index];
    else if ([components size] - index == 2)
        [self addKPObserver:KPO
                forProperty:[components at:index + 1]
                   ofObject:object
                  withIndex:index];
    else
    {
        id next = [object valueForKey:[components at:index + 1]];

        [self addKPObserver:KPO
                forProperty:[components at:index + 1]
                   ofObject:object
                  withIndex:index];
        [self addObserverForKeyPath:keyPath
                           ofObject:next
                            withKPO:KPO
                          fromIndex:index++];
    }
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
    [self addObserverForKeyPath:keyPath
                       ofObject:object
                        withKPO:kpo
                      fromIndex:0];
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
    [self addObserverForKeyPath:keyPath
                       ofObject:object
                        withKPO:kpo
                      fromIndex:0];
}

- removeObserver:observer forKeyPath:keyPath ofObject:object {}

@end
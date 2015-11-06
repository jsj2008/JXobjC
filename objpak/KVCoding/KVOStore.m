/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Block.h"
#import "Exceptn.h"
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
    Pair * key            = [Pair pairWithVolatileFirst:object second:propStr];
    KPObserverRef * value = [KPObserverRef kpoRefWithKPO:kpo pathIndex:index];

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
    if (!object)
        [Exception signal:"Keypath is broken"];
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

+ recreateKPOsFromIndex:i forObserver:observer
{
    /*id matchDetector = { :candidate |
                          [candidate matchesRoot:object] &&
                            [candidate matchesObserver:observer] &&
                            [candidate matchesKeyPath:keyPath]
                            };*/
    return self;
}

/* Re-create the registrations for a keypath, starting with registration at
 * the specified index. */
+ recreateKPOsForKeyPath:keyPath
                ofObject:object
               fromIndex:(unsigned int)index
             withNewRoot:newRoot
{
    volatile id tSelf   = self;
    Dictionary * kToObs = keyToObservers;
    id matchDetector    = {
        : candidate | [candidate.reference matchesRoot:object] &&
              [candidate.reference matchesKeyPath:keyPath] /* &&
              candidate.reference.pathIndex >= index */
    };
    id KPOs = [observers detect:matchDetector];

    if (newRoot)
        [KPOs do:{ : each | [each setRoot:newRoot]}];

    [kToObs do:
            { :key | id val, intersect;
                val       = [kToObs atKey:key];
                intersect = [val detect:matchDetector];
                [val removeAll:intersect];

                if (![val size])
                    [kToObs removeKey:key];
                else
                    val = nil; /* don't delete it if it isn't empty */
#ifndef OBJC_ARC
                [[intersect freeContents] free];
                [val free];
#endif
            }];

    /* Later, this should be invoked only from index downwards. */
    if (newRoot)
        [KPOs do:
              { :each | [tSelf addObserverForKeyPath:keyPath
                     ofObject:newRoot ? : object
                      withKPO:each
                    fromIndex:0];
              }];

    return self;
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

+ (void)removeObserver:observer forKeyPath:keyPath ofObject:object
{
    Dictionary * kToObs = keyToObservers;
    id matchDetector    = { : cand | id candidate;
    candidate           = [cand reference];
    [candidate matchesRoot:object] && [candidate matchesObserver:observer] &&
        [candidate matchesKeyPath:keyPath]
};
id subset = [observers detect:matchDetector];

[observers removeAll:subset];
[kToObs do:
        { :key | id val, intersect;
            val       = [kToObs atKey:key];
            intersect = [val detect:matchDetector];
            [val removeAll:intersect];

            if (![val size])
                [kToObs removeKey:key];
#ifndef OBJC_ARC
            [[intersect freeContents] free];
            [val free];
#endif
        }];

#ifndef OBJC_ARC
[[subset freeContents] free];
#endif
}

@end
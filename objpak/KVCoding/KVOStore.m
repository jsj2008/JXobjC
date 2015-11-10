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
    Pair * key = [Pair pairWithVolatileFirst:object second:propStr];
    KPObserverRef * value =
        [KPObserverRef kpoRefWithKPO:(volatile id)kpo pathIndex:index];
    id obsSet;

    if (!keyToObservers)
        keyToObservers = [Dictionary new];
    if (!(obsSet = [keyToObservers atKey:key]))
        [keyToObservers atKey:key put:[Set new]];
    [[keyToObservers atKey:key] ?: [keyToObservers atKey:key put:[Set new]]
        add:value];
    if (!observers)
        observers = [Set new];
    [observers add:kpo];
}

+ (void)addObserverForKeyPath:keyPath
                     ofObject:object
                      withKPO:KPO
                    fromIndex:(unsigned int)index
{
    OrdCltn * components = [KPO keyPathComponents];

    /**
      * The following procedure must be followed for a key of X.Y.Z
      * First, watch object.X. Next, X.Y. Finally, Y.Z.
      *
      * This is implemented through recursion, using an `index' parameter
      * specifying the subcomponent of the path representing the current
      * property we'd like to watch. We also specify at each call the current
      * object we want to add a watch on; each call, we resolve the current
      * index's mapping into the current object's property of that name. This
      * is done before calling this method method so that this method can be
      * more purely implemented, i.e. totally recursively.
      *
      * Let's consider that key's computation:
      * [components size] would be 3
      * The index for final would be 2 (which maps to the terminal property)
      * idx|watch
      *  0 |self.X
      *  1 |X.Y
      *  2 |Y.Z
     **/

    if (!object)
        [Exception signal:"Keypath is broken"];
    if ([components size] - index == 1) /* just-a-key case */
        [self addKPObserver:KPO
                forProperty:[components at:index]
                   ofObject:object
                  withIndex:index];
    else
    {
        id next = [object valueForKey:[components at:index]];

        [self addKPObserver:KPO
                forProperty:[components at:index]
                   ofObject:object
                  withIndex:index];
        [self addObserverForKeyPath:keyPath
                           ofObject:next
                            withKPO:KPO
                          fromIndex:++index];
    }
}

/* Re-create the registrations for a keypath, starting with registration at
 * the specified index. */
+ recreateKPOsForKeyPath:keyPath
                ofObject:object
               fromIndex:(unsigned int)index
             withNewRoot:newRoot
{
    id tSelf            = self;
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
                {
                    [kToObs removeKey:key];
                }
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

+ (void)sendKVOForObject:object
                property:propStr
                oldValue:oldValue
                newValue:newValue
{
    Pair * key = (Pair *)[Pair pairWithVolatileFirst:object second:propStr];
    Set * obs  = (Set *)[keyToObservers atKey:key];

    [obs do:
         { :each | [each.reference fireForOldValue:oldValue newValue:newValue];
         }];

#ifndef OBJC_REFCNT
    [key free];
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
    [kpo setRoot:object];

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
    [kpo setRoot:object];
    [self addObserverForKeyPath:keyPath
                       ofObject:object
                        withKPO:kpo
                      fromIndex:0];
}

+ (void)removeObserversByObserverFilter:aBlk
{
    Dictionary * kToObs = keyToObservers;
    id subset;

    subset = [observers select:{ : c | [aBlk value:c]}];
    [observers removeAll:subset];

    [kToObs keysDo:
            { :key | id val, intersect;
                val       = [kToObs atKey:key];
                intersect = [val select:{ : c | [aBlk value:c.reference]}];

                [val removeAll:intersect];
                if (![val size])
                {
                    [kToObs removeKey:key];
                    [val free];
                }
#ifndef OBJC_ARC
                [[intersect freeContents] free];
#endif
            }];

#ifndef OBJC_ARC
    [[subset freeContents] free];
#endif
}

+ (void)removeObserver:observer forKeyPath:keyPath ofObject:object
{
    [self removeObserversByObserverFilter:{ : c |
        [c matchesRoot:object] && [c matchesObserver:observer] &&
        [c matchesKeyPath:keyPath]
        }];
}

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "Dictionary.h"
#import "OCString.h"
#import "Set.h"
#import "VolatileReference.h"

@interface KPObserver : Object
{
    /* The original key path. */
    String * keyPath;
    id userInfo;

    /* Perform a selector on a observer. Note that observer is also used to
     * track the lifetime of an observer, by associating the observation's
     * creator, even if they used a block instead. */
    SEL selector;
    volatile id observer;

    /* or, alternatively, a block: */
    id block;
}

+ newWithKeyPath:kp selector:(SEL)sel observer:targ userInfo:arg;
+ newWithKeyPath:kp block:blk observer:targ userInfo:arg;

- initWithKeyPath:kp selector:(SEL)sel observer:targ userInfo:arg;
- initWithKeyPath:kp block:blk observer:targ userInfo:arg;

- (BOOL)matchesSelector:(SEL)sel observer:targ userInfo:arg;
- (BOOL)matchesObserver:targ;
- (BOOL)matchesBlock:blk userInfo:arg;
- (BOOL)matchesBlock:blk;
- (BOOL)matchesKeyPath:kp;

- (String *)keyPath;
- (void)fire:information;

@end

@interface KPObserverRef : VolatileReference
{
    /* This specifies the index within the components of a keypath that
     * this entry represents.
     * For example, if an instance is referenced for the Y.Z pair of the
     * X.Y.Z keypath, then this number is 1. */
    unsigned int pathIndex;
}

+ kpoRefWithPathIndex:(unsigned int)anIndex;

- (unsigned int)pathIndex;

@end

@interface KVOStore : Object
{
} :
{
    /* This dictionary is keyed by Pairs; each Pair consists of a
     * VolatileReference to an object, and a (nonvolatile) property name.
     * These keys map to Sets of KPObserverRefs.*/
    Dictionary * keyToObservers;

    /* This is the owning set of the KPObservers.
     * Its entries represent the event-independent component of an observation.
     * The data stored therein is sufficient to reconstruct a broken tree
     * corresponding to a keypath. */
    Set * observers;
}

+ (void)addObserver:observer
         forKeyPath:keyPath
           ofObject:object
          withBlock:blk
           userInfo:ui;
+ (void)addObserver:observer
         forKeyPath:keyPath
           ofObject:object
       withSelector:(SEL)sel
           userInfo:ui;

@end
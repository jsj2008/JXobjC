/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "Dictionary.h"
#import "OCString.h"
#import "Set.h"

@interface KPObserver : Object
{
    /* The key paths that trigger a notification.
     * For example, X.Y.Z will have X.Y, and Y.Z.
     * The set contains Pair entries where .first is the object and .second is
     * the property name - so it can be compared to entries in the
     * observed-properties table with isEqual:. */
    Set * pathTriggers;
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

@interface KVOStore : Object
{
} :
{
    /* This is a dictionary of VolatileReferences corresponding to the objects
     * that own the property represented in a keypath.
     * It maps to another dictionary; a dictionary of property names mapped to
     * a set of KPObservers. */
    Dictionary * ownerRefToKPObserverDict;
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
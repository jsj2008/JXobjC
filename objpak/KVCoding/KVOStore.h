/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "Dictionary.h"
#import "OCString.h"

@interface KPObserver : Object
{
    /* Perform a selector on a target. Note that target is also used to
     * track the lifetime of an observer, by associating its 'originator'. */
    SEL selector;
    volatile id target;

    /* or, alternatively, a block: */
    id block;

    id userInfo;
    String * keyPath;
}

+ newWithKeyPath:kp selector:(SEL)sel target:targ userInfo:arg;
+ newWithKeyPath:kp block:blk target:targ userInfo:arg;

- initWithKeyPath:kp selector:(SEL)sel target:targ userInfo:arg;
- initWithKeyPath:kp block:blk target:targ userInfo:arg;

- (BOOL)matchesSelector:(SEL)sel target:targ userInfo:arg;
- (BOOL)matchesTarget:targ;
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
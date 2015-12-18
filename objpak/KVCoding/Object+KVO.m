/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <ctype.h>

#import "Object.h"
#import "Block.h"
#import "OCString.h"
#import "OrdCltn.h"
#import "KVC.h"
#import "KVO.h"
#import "KVOStore.h"
#import "Pair.h"

@protocol KVOSwiz
- (void)sendKVOForProperty:propStr oldValue:oldValue newValue:newValue;
- (void)sendKVOForProperty_swiz:propStr oldValue:oldValue newValue:newValue;

- finalise_swiz;
@end

@implementation Object (KeyValueObserving)

- (void)replaceKVOMeths
{
    id cls           = [self class];
    ocMethod oldSend = getInstanceMethod (
                 cls, @selector (sendKVOForProperty:oldValue:newValue:)),
             newSend = getInstanceMethod (
                 cls, @selector (sendKVOForProperty_swiz:oldValue:newValue:)),
             oldFinalise = getInstanceMethod (cls, @selector (finalise)),
             newFinalise = getInstanceMethod (cls, @selector (finalise_swiz));

    exchangeImplementations (oldSend, newSend);
    exchangeImplementations (oldFinalise, newFinalise);
}

- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel userInfo:ui
{
    [self replaceKVOMeths];
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
             withSelector:sel
                 userInfo:ui];
}

- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel
{
    [self replaceKVOMeths];
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
             withSelector:sel
                 userInfo:nil];
}

- (void)addObserver:observer forKeyPath:keyPath block:blk userInfo:ui
{
    [self replaceKVOMeths];
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
                withBlock:blk
                 userInfo:ui];
}

- (void)addObserver:observer forKeyPath:keyPath block:blk
{
    [self replaceKVOMeths];
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
                withBlock:blk
                 userInfo:nil];
}

- (void)removeObserver:observer forKeyPath:keyPath
{
    [KVOStore removeObserver:observer forKeyPath:keyPath ofObject:self];
}

- (void)sendKVOForProperty_swiz:propStr oldValue:oldValue newValue:newValue
{
    [KVOStore sendKVOForObject:self
                      property:propStr
                      oldValue:oldValue
                      newValue:newValue];
}

- finalise_swiz
{
    [KVOStore removeObserversOfObject:self];
    return [self finalise_swiz];
}

@end
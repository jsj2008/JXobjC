/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <ctype.h>

#import "Block.h"
#import "OCString.h"
#import "OrdCltn.h"
#import "KVC.h"
#import "KVO.h"
#import "KVOStore.h"
#import "Pair.h"

@implementation Object (KeyValueObserving)

- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel userInfo:ui
{
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
             withSelector:sel
                 userInfo:ui];
}

- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel
{
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
             withSelector:sel
                 userInfo:nil];
}

- (void)addObserver:observer forKeyPath:keyPath block:blk userInfo:ui
{
    [KVOStore addObserver:observer
               forKeyPath:keyPath
                 ofObject:self
                withBlock:blk
                 userInfo:ui];
}

- (void)addObserver:observer forKeyPath:keyPath block:blk
{
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

- (void)sendKVOForProperty:propStr oldValue:oldValue newValue:newValue
{
    [KVOStore sendKVOForObject:self
                      property:propStr
                      oldValue:oldValue
                      newValue:newValue];
}

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "OCString.h"

@interface Object (KeyValueObserving)

- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel userInfo:ui;
- (void)addObserver:observer forKeyPath:keyPath selector:(SEL)sel;

- (void)addObserver:observer forKeyPath:keyPath block:blk userInfo:ui;
- (void)addObserver:observer forKeyPath:keyPath block:blk;

- (void)removeObserver:observer forKeyPath:keyPath;

@end
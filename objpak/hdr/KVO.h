/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface Object (KeyValueObserving)

- (void)addObserver:observer forKeyPath:keyPath;

@end
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

- (void)addObserver:observer forKeyPath:keyPath;

@end
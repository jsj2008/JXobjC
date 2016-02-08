/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include "Dictionary.h"

@implementation Dictionary (KVC)

- valueForKey:key { return [self atKey:key]; }

- (void)setValue:value forKey:key { [self atKey:key put:value]; }

@end
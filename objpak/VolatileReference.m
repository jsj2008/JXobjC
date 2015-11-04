/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "VolatileReference.h"

@implementation VolatileReference

- (unsigned)hash { return [referredObject hash]; }

- (BOOL)isEqual:anObject { return [referredObject isEqual:anObject]; }

@end
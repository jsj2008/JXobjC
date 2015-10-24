/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface Object (KeyValueCoding)

- (id)valueForKey:key;
- (void)setValue:value forKey:key;

- (id)valueForKeyPath:keyPath;
- (void)setValue:value forKeyPath:keyPath;

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

/*!
 * @abstract Pair
 * @discussion Stores a pair of objects.
 * @indexgroup Collection
 */
@interface Pair : Object

/*!
 * The two elements of the pair.
 */
@property id first, second;

@property volatile char comparator;

/*!
 * Creates a new pair from two specified objects.
 * @param one The first object for the pair.
 * @param two The second object for the pair.
 */
+ (Pair *)pairWithFirst:one second:two;

+ (Pair *)pairWithVolatileFirst:one volatileSecond:two;
+ (Pair *)pairWithVolatileFirst:one second:two;

- initWithFirst:one second:two;

/*! A utility method for combining two hashes into one unique combination. */
+ (uintptr_t)combineHash:(uintptr_t)first withHash:(uintptr_t)second;

@end
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

#ifndef VOLATILEREFERENCE_H
#define VOLATILEREFERENCE_H

/*!
 * @abstract Ordered collection of objects.
 * @discussion Stores a reference to an object (of type <em>T</em>) which is not
 * visible to the Garbage Collector. Further, when the object referenced should
 * be collected, the VolatileReference will respond <bold>YES</bold> when sent
 * the @link isValid @/link message.
 * @indexgroup Container
 */
@interface VolatileReference <T> : Object
{
    volatile id *reference;
}

/* Creates a new VolatileReference with the specified object reference. */
- (VolatileReference<T>)newWithReference:(volatile T)ref;
/*! Initialises a new VolatileReference with the specified object reference. */
- (VolatileReference<T>)initWithReference:(volatile T)ref;
/*! Retrieves the object reference hidden inside. If the object has since been
 * deallocates, returns nil. */
- (T)reference;
/*! Retrieves the original value of object reference hidden inside. */
- (T)originalReference;
/*! Answers whether the referenced object is valid and still exists. */
- (BOOL)isValid;

@end

#endif

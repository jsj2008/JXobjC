/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef __RTOBJECT_H__
#define __RTOBJECT_H__

#include "objcrt.h"
#include <stdarg.h>
#include <string.h>

/*!
 RtObject is the terminal root class.
 It implements behaviour that virtually every object, even unusual ones,
 could expect.

 Users should inherit instead from a primary or secondary root class.
 @indexgroup JX Runtime
 */
@interface RtObject : nosuper
{
    id isa;
    unsigned int _refcnt;
    void * _lock;
}

/*! @group Creating, copying, and deallocating instances */

/*! When the program starts, every class receives this message.
    It may be used for pre-use initialisation. */
+ initialize;

/*!
  Allocates and initialises a new instance of the class.
  It is equivalent to [[class @link alloc @/link] @link init @/link];
 */
+ new;

/*!
  Allocates a new instance of the class.
  The object may be unusable until init or a delegated initialiser method
  is called. The default alloc simply zeroes all instance variables.
 */
+ alloc;

/*! Initialises an allocated instance of the class. */
- init;

/*!
  Copies the instance, but may not copy all internal data-structures.
  The copied object includes byte-for-byte copies of all its instance
  variables, whereas (for example) recursive copying of <em>id</em> (object
  identifier) variables. */
- copy;

/*! Deep-copies the instance, copying any internal data-structures. */
- deepCopy;

/*! Frees the instance. */
- free;

- increfs;
- decrefs;
/*! Finalises an instance due to be freed by the garbage collector. */
- finalise;

/*! @group Introspecting instances */

/*! Returns the instance. */
- self;
/*! Returns the instance. */
- yourself;

/*! @group Message forwarding */

/*!
  Invoked when a message is not understood. The message may be sent onwards
  to another object, or treated as desired. By default, invokes
  @link doesNotRecognize: @/link.
  @param aMessage A @link Message @/link object representing the message that
  was not understood.
 */
- doesNotUnderstand:aMessage;

/*!
  Invoked when a message is not recognised by @link doesNotUnderstand: @/link.
  Terminates programme by default.
  @param aSelector The selector that was not understood.
 */
- (id)doesNotRecognize:(SEL)aSelector;

/*! @group Retrieving information about messages */

/*! Look up a message with the object by selector.
    @param aSelector The SEL to be looked up. */
- (IMP)methodFor:(SEL)aSelector;

/*! Look up the IMP of a method for an instance of this class, by selector.
     @param aSelector The SEL to be looked up. */
+ (IMP)instanceMethodFor:(SEL)aSelector;

/* private */
- _lock;
- _unlock;
- ARC_dealloc;
@end

#endif

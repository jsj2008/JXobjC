/*
 * Portable Object Compiler (c) 1997,98,2000,03,14.  All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __BLOCK_H__
#define __BLOCK_H__

#include <stdio.h> /* because Object.h can be from another runtime */
#include "Object.h"

/* allows "manual" construction of Blocks, ie. without compiler support */
extern id EXPORT newBlock (int n, IMP fn, void * data, IMP dtor);

/*!
 Implements Blocks, which are often known as Lambda expressions or Enclosures.
 These couple a method with the environment in which it was defined. They can
 be used to similar effect to function pointers, but with a great deal more
 flexibility and simplicity.

 You may implement a block accepting two <em>id</em>-type parameters and
 returning the answer to the @link self @/link message sent to the second
 in this way:
 <tt>
 Block * aBlock = {:first :second | [second self]};
 </tt>
 @indexgroup JX Runtime
 */
@interface Block : Object
{
    IMP fn;   /* it's not _really_ an IMP, it's just a func pointer */
    IMP dtor; /* idem */
    int nVars;
    void ** data;
    id nextBlock;
}

+ errorHandler;
+ errorHandler:aHandler;
+ halt:message value:receiver;

/*! @group Calling the block */

/*! Calls into the block.
    @return The <em>id</em>-type return value of the block. */
- value;

/*! Calls into the block.
    @return The <em>int</em>-type return value of the block. */
- (int)intvalue;

/*! Schedules a call into the block for just before programme exit. */
- atExit;

/*!
  Calls into the block with a parameter.
  @param anObject An <em>id</em>-type parameter to the block.
  @return The <em>id</em>-type return value of the block. */
- value:anObject;

/*!
  Calls into the block with a parameter.
  @param anObject An <em>id</em>-type parameter to the block.
  @return The <em>int</em>-type return value of the block. */
- (int)intvalue:anObject;

/*!
  Calls into the block with two parameters.
  @param firstObject The first <em>id</em>-type parameter to the block.
  @param secondObject The second parameter.
  @return The <em>id</em>-type return value of the block. */
- value:firstObject value:secondObject;

/*!
  Calls into the block with two parameters.
  @param firstObject The first <em>id</em>-type parameter to the block.
  @param secondObject The second parameter.
  @return The <em>int</em>-type return value of the block. */
- (int)intvalue:firstObject value:secondObject;

/*!
  Calls into the block repeatedly for a certain number of times.
  @param n How many times to repeat the call.
  @return The block itself. */
- repeatTimes:(int)n;

/*! @group Calling with exception handling */

/*!
  Calls into the block. If an exception is raised, deploys a handler block with
  two arguments (the @link Message @/link first, and then the object to which
  the sent message triggered an exception.)
  @param aHandler Block taking two arguments (:msg and :rcv) for handling the
  exception.
  @return The <em>id</em>-type return value of the block. */
- ifError:aHandler;

/*!
  Calls into the block with an <em>id</em>-type parameter. If an exception is
  raised, deploys a handler block.
  @param anObject <em>id</em>-type argument to the block.
  @param aHandler Block handling any exception raised.
  @return The <em>id</em>-type return value of the block. */
- value:anObject ifError:aHandler;

/*!
  Calls into the block. If an exception is raised and matches the specified
  class of exceptions (the exception is an instance of the class, or of one of
  its subclasses,) a handler block is called with its single argument being
  the instance of the exception raised.
  @param aClassOfExceptions The @link Exception @/link class, or one of its
  subclasses.
  @param aHandler Block taking an argument (:except) for handling the
  exception.
  @return The <em>id</em>-type return value of the block. */
- on:aClassOfExceptions do:aHandler;

/*!
  Calls into the block with an <em>id</em>-type parameter. If an exception is
  raised and matches the specified class of exceptions, deploys a handler
  block.
  @param aClassOfExceptions The @link Exception @/link class, or one of its
  subclasses.
  @param aHandler Block taking an argument (:except) for handling the
  exception.
  @return The <em>id</em>-type return value of the block. */
- value:anObject on:aClassOfExceptions do:aHandler;

/* private */

/* Blocks are not manually created or deleted; the compiler automatically
 * handles them, including automatic referencecounting memory management. */
- blkc:(int)n blkfn:(IMP)f blkv:(void **)d blkdtor:(IMP)c;
+ new;
- copy;
- deepCopy;
+ blkc:(int)n blkfn:(IMP)f blkv:(void **)d blkdtor:(IMP)c;
- free;
- ARC_dealloc;

- push:aBlock;
- pop;

- errorNumArgs;
- errorGoodHandler;

- shouldNotImplement;
- printOn:(IOD)anIod;
@end

#endif /* __BLOCK_H__ */

/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

/* This partially abstract class defines an IODevice. */
@interface IODevice : Object
{
    char *readBuffer, *writeBuffer;
    size_t readBufferLength, writeBufferLength;
}

@property BOOL blocking, buffered;
@property /* (readonly) */ BOOL atEndOfStream;

- (void)close;

- (void)flushReads;
- (void)flushWrites;

- (size_t)rawReadIntoBuffer:(void *)buffer length:(size_t)length;
- (void)rawWriteBuffer:(const void *)buffer length:(size_t)length;

/* Retrieve a file descriptor for reading or writing to respectively ✔ */
- (int)readFileDescriptor;
- (int)writeFileDescriptor;

@end
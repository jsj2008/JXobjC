/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

/*!
 * @abstract I/O Device
 * @discussion Partially abstract class implementing a generic bidirectional
 * I/O device.
 * @indexgroup I/O
 */
@interface IODevice : Object
{
    char *readBuffer, *writeBuffer;
    size_t readBufferLength, writeBufferLength;
}

@property BOOL blocking, buffered;

/*! Whether the I/O Device has reached the end of its stream. */
@property /* (readonly) */ BOOL atEndOfStream;

/*! Closes the I/O device. */
- (void)close;

/*! Flushes any impending reads in the buffer. */
- (void)flushReads;

/*! Flushes any impending writes in the buffer.*/
- (void)flushWrites;

/*!
 * Reads from the I/O device into a byte buffer.
 * @param buffer Buffer into which to read.
 * @param length Number of bytes to read into buffer.
 */
- (size_t)rawReadIntoBuffer:(void *)buffer length:(size_t)length;

/*!
 * Writes a byte buffer to the I/O device.
 * @param buffer Buffer to write to device.
 * @param length Number of bytes to write to device.
 */
- (void)rawWriteBuffer:(const void *)buffer length:(size_t)length;

/*! Retrieves an associated file descriptor for the I/O device (if available)
    for reading from ✔ */
- (int)readDescriptor;

/*! Retrieves an associated file descriptor for the I/O device (if available)
    for writing to ✔ */
- (int)writeDescriptor;

@end
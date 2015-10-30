/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Pipe.h"

@implementation Pipe

+ ARC_dealloc
{
    [self close];
    return [super ARC_dealloc];
}

- (void)close
{
#if defined(OBJC_WINDOWS)
    [writeFd close];
    [readFd close];
#else
    close (writeFd);
    close (readFd);
#endif
}

- (void)flushReads;
- (void)flushWrites;

- (size_t)rawReadIntoBuffer:(void *)buffer length:(size_t)length
{
#if defined(OBJC_WINDOWS)
    return [readFd rawReadIntoBuffer:buffer length:length];
#else
    return read (readFd, buffer, length);
#endif
}

- (void)rawWriteBuffer:(const void *)buffer length:(size_t)length
{
#if defined(OBJC_WINDOWS)
    [writeFd rawWriteBuffer:buffer length:length];
#else
    write (writeFd, buffer, length);
#endif
}

/* Retrieve a file descriptor for reading or writing to respectively ✔ */
- (int)readFileDescriptor
{
#if defined(OBJC_WINDOWS)
    return [readFd readFileDescriptor];
#else
    return readFd;
#endif
}

- (int)writeFileDescriptor
{
#if defined(OBJC_WINDOWS)
    return [writeFd writeFileDescriptor];
#else
    return writeFd;
#endif
}

@end

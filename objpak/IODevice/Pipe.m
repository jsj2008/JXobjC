/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Pipe.h"
#import "Exceptn.h"

@implementation Pipe

- ARC_dealloc
{
    [self close];
    return [super ARC_dealloc];
}

- init
{
#if !defined(OBJC_WINDOWS)
    int pipefds[2];
    unsigned short port;
#endif

    [super init];
#if defined(OBJC_WINDOWS)
    readFd = [TCPSocket new];
    port   = [readFd bindToHostname:@"127.0.0.1" port:0];
    [readFd listen];
    writeFd = [[TCPSocket new] connectToHostname:@"127.0.0.1" port:port];
    readFd  = [readFd accept];
#else
    pipe2 (pipefds, SOCK_CLOEXEC);
    readFd  = pipefds[0];
    writeFd = pipefds[1];
#endif

    return self;
}

- (void)close
{
#if defined(OBJC_WINDOWS)
    [writeFd close];
    [readFd close];
    writeFd = nil;
    readFd  = nil;
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

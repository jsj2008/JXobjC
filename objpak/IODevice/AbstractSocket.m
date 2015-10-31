/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stdio.h>
#include "private/_sockets.h"

#import "Exceptn.h"
#import "AbstractSocket.h"

@implementation AbstractSocket

+ initialize
{
#if defined(OBJC_WINDOWS)
    WSADATA wsadata;
    WSAStartup (MAKEWORD (2, 0), &wsadata);
#endif

    return self;
}

- init
{
    [super init];
    descriptor = -1;
    return self;
}

- ARC_dealloc
{
    [self close];
    return [super ARC_dealloc];
}

- (void)close
{
    if ((int)descriptor != -1)
        sockclose (descriptor);
}

- (size_t)rawReadIntoBuffer:(void *)buffer length:(size_t)length
{
    ssize_t ret;

    if ((ret = recv (descriptor, buffer, length, 0)) < 0)
        [Exception signal:"Failure in recv()"];
    else if (!ret)
        [self setAtEndOfStream:YES];

    return ret;
}

- (void)rawWriteBuffer:(const void *)buffer length:(size_t)length
{
    if (send (descriptor, buffer, length, 0) != (ssize_t)length)
        [Exception signal:"Failure in send()"];
}

- (int)readDescriptor { return (int)descriptor; }

- (int)writeDescriptor { return (int)descriptor; }

- (void)_setDescriptor:(SocketDescriptor)fd { descriptor = fd; }
- (SocketDescriptor)_descriptor { return descriptor; }

@end

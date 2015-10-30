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
    if ((int)descriptor != -1)
        close (descriptor);
    return [super ARC_dealloc];
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

- (int)readFileDescriptor { return (int)descriptor; }

- (int)writeFileDescriptor { return (int)descriptor; }

@end

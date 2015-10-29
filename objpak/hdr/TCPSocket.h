/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "_sockets.h"

#import "AbstractSocket.h"
#import "OCString.h"

/* This class defines a TCP socket. */

@interface TCPSocket : AbstractSocket
{
    struct sockaddr * address;
    socklen_t addressLength;
}

@property /* (readonly) */ BOOL listening;
@property BOOL keepAlive;

- connectToHost:(String *)host port:(unsigned short)port;

/* A port of 0 will result in the choosing of a random port.
 * That port number will be returned. */
- (unsigned short)bindToHost:(String *)host port:(unsigned short)port;

- (void)listen;

@end